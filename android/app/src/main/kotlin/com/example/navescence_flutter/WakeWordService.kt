package com.example.navescence_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService
import org.vosk.android.StorageService
import java.text.Normalizer
import java.util.Locale

class WakeWordService : Service(), RecognitionListener, TextToSpeech.OnInitListener {

    companion object {
        const val ACTION_INICIAR =
            "com.example.navescence_flutter.INICIAR_WAKE_WORD"

        const val ACTION_OUVIR =
            "com.example.navescence_flutter.OUVIR_WAKE_WORD"

        const val ACTION_PAUSAR =
            "com.example.navescence_flutter.PAUSAR_WAKE_WORD"

        const val ACTION_PARAR =
            "com.example.navescence_flutter.PARAR_WAKE_WORD"

        const val ACTION_COMANDO_RECONHECIDO =
            "com.example.navescence_flutter.COMANDO_RECONHECIDO"

        const val EXTRA_COMANDO = "comando"

        private const val CHANNEL_ID = "navescence_wake_word"
        private const val NOTIFICATION_ID = 731
        private const val TAG = "NAVESCENCE"
    }

    private enum class ModoEscuta {
        AGUARDANDO_ATIVACAO,
        RESPONDENDO,
        AGUARDANDO_COMANDO,
    }

    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var speechService: SpeechService? = null

    private var modeloCarregando = false
    private var deveOuvir = false
    private var escutando = false

    private var ttsPronto = false
    private var ultimaAtivacao = 0L

    private var modo = ModoEscuta.AGUARDANDO_ATIVACAO

    private lateinit var tts: TextToSpeech

    private val handler = Handler(Looper.getMainLooper())

    private val timeoutComando = Runnable {
        if (modo != ModoEscuta.AGUARDANDO_COMANDO) return@Runnable

        Log.d(
            TAG,
            "Tempo do comando esgotado.",
        )

        speechService?.setPause(true)

        modo = ModoEscuta.RESPONDENDO

        if (ttsPronto) {
            tts.speak(
                "Não entendi. Diga Nave novamente.",
                TextToSpeech.QUEUE_FLUSH,
                null,
                "comando_timeout",
            )
        } else {
            handler.postDelayed({
                voltarParaWakeWord()
            }, 500)
        }
    }

    override fun onCreate() {
        super.onCreate()

        criarCanalNotificacao()

        tts = TextToSpeech(this, this)

        tts.setOnUtteranceProgressListener(
            object : UtteranceProgressListener() {

                override fun onStart(utteranceId: String?) {}

                override fun onDone(utteranceId: String?) {
                    when (utteranceId) {
                        "wake_response" -> {
                            handler.post {
                                iniciarModoComando()
                            }
                        }

                        "comando_timeout" -> {
                            handler.post {
                                voltarParaWakeWord()
                            }
                        }
                    }
                }

                override fun onError(utteranceId: String?) {
                    handler.post {
                        when (utteranceId) {
                            "wake_response" -> iniciarModoComando()
                            else -> voltarParaWakeWord()
                        }
                    }
                }
            },
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        iniciarForeground()

        when (intent?.action) {
            ACTION_INICIAR -> {
                deveOuvir = true
                carregarModelo()
            }

            ACTION_OUVIR -> {
                deveOuvir = true

                if (model == null) {
                    carregarModelo()
                } else {
                    iniciarEscuta()
                }
            }

            ACTION_PAUSAR -> {
                deveOuvir = false
                pausarEscuta()
            }

            ACTION_PARAR -> {
                stopSelf()
            }

            else -> {
                deveOuvir = true
                carregarModelo()
            }
        }

        return START_STICKY
    }

    private fun iniciarForeground() {
        val notificacao = criarNotificacao()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notificacao,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
        } else {
            startForeground(
                NOTIFICATION_ID,
                notificacao,
            )
        }
    }

    private fun carregarModelo() {
        if (model != null || modeloCarregando) return

        modeloCarregando = true

        Log.d(
            TAG,
            "Carregando modelo português...",
        )

        StorageService.unpack(
            this,
            "model-pt",
            "model-pt-runtime",
            { modelo ->
                model = modelo
                modeloCarregando = false

                Log.d(
                    TAG,
                    "Modelo Vosk carregado.",
                )

                if (deveOuvir) iniciarEscuta()
            },
            { erro ->
                modeloCarregando = false

                Log.e(
                    TAG,
                    "Erro ao carregar modelo: ${erro.message}",
                    erro,
                )
            },
        )
    }

    private fun iniciarEscuta() {
        if (!deveOuvir) return

        try {
            if (speechService == null) {
                val modelo = model ?: return

                recognizer = Recognizer(
                    modelo,
                    16000.0f,
                )

                speechService = SpeechService(
                    recognizer,
                    16000.0f,
                )

                speechService?.startListening(this)

                escutando = true
                modo = ModoEscuta.AGUARDANDO_ATIVACAO

                Log.d(
                    TAG,
                    "Microfone ativo. Diga NAVE.",
                )

                return
            }

            voltarParaWakeWord()
        } catch (erro: Exception) {
            Log.e(
                TAG,
                "Erro ao iniciar reconhecimento.",
                erro,
            )
        }
    }

    private fun pausarEscuta() {
        if (!escutando) return

        handler.removeCallbacks(timeoutComando)

        speechService?.setPause(true)

        Log.d(
            TAG,
            "Reconhecimento pausado.",
        )
    }

    private fun processarHipotese(json: String, campo: String) {
        try {
            val texto =
                JSONObject(json)
                    .optString(campo)
                    .trim()

            if (texto.isEmpty()) return

            val normalizado = normalizar(texto)

            Log.d(
                TAG,
                "VOSK [$campo]: $texto",
            )

            when (modo) {
                ModoEscuta.AGUARDANDO_ATIVACAO -> {
                    if (palavraChaveDetectada(normalizado)) {
                        ativarAssistente()
                    }
                }

                ModoEscuta.AGUARDANDO_COMANDO -> {
                    if (campo == "text") {
                        comandoReconhecido(texto)
                    }
                }

                ModoEscuta.RESPONDENDO -> {
                    // Ignora reconhecimento enquanto o sistema fala.
                }
            }
        } catch (erro: Exception) {
            Log.e(
                TAG,
                "Erro ao interpretar resultado Vosk.",
                erro,
            )
        }
    }

    private fun palavraChaveDetectada(texto: String): Boolean {
        val possibilidades = setOf(
            "nave",
            "naves",
        )

        return texto.trim() in possibilidades
    }

    private fun ativarAssistente() {
        if (modo != ModoEscuta.AGUARDANDO_ATIVACAO) return

        val agora = System.currentTimeMillis()

        if (agora - ultimaAtivacao < 2500) return

        ultimaAtivacao = agora
        modo = ModoEscuta.RESPONDENDO

        Log.d(
            TAG,
            "PALAVRA-CHAVE DETECTADA!",
        )

        speechService?.setPause(true)

        vibrar()

        if (ttsPronto) {
            tts.speak(
                "Pode falar.",
                TextToSpeech.QUEUE_FLUSH,
                null,
                "wake_response",
            )
        } else {
            iniciarModoComando()
        }
    }

    private fun iniciarModoComando() {
        if (!deveOuvir) return

        modo = ModoEscuta.AGUARDANDO_COMANDO

        speechService?.reset()
        speechService?.setPause(false)

        handler.removeCallbacks(timeoutComando)
        handler.postDelayed(
            timeoutComando,
            8000,
        )

        Log.d(
            TAG,
            "Aguardando comando...",
        )
    }

    private fun comandoReconhecido(comando: String) {
        if (modo != ModoEscuta.AGUARDANDO_COMANDO) return

        handler.removeCallbacks(timeoutComando)

        modo = ModoEscuta.RESPONDENDO

        speechService?.setPause(true)

        Log.d(
            TAG,
            "COMANDO CAPTURADO: $comando",
        )

        val intent =
            Intent(
                ACTION_COMANDO_RECONHECIDO,
            ).apply {
                setPackage(packageName)
                putExtra(
                    EXTRA_COMANDO,
                    comando,
                )
            }

        sendBroadcast(intent)

        handler.postDelayed({
            voltarParaWakeWord()
        }, 800)
    }

    private fun voltarParaWakeWord() {
        handler.removeCallbacks(timeoutComando)

        modo = ModoEscuta.AGUARDANDO_ATIVACAO

        if (!deveOuvir) return

        if (speechService == null) {
            iniciarEscuta()
            return
        }

        speechService?.reset()
        speechService?.setPause(false)

        Log.d(
            TAG,
            "Aguardando NAVE...",
        )
    }

    private fun normalizar(texto: String): String {
        val semAcento =
            Normalizer.normalize(
                texto.lowercase(
                    Locale("pt", "BR"),
                ),
                Normalizer.Form.NFD,
            ).replace(
                Regex("\\p{Mn}+"),
                "",
            )

        return semAcento
            .replace(
                Regex("[^a-z0-9 ]"),
                " ",
            )
            .replace(
                Regex("\\s+"),
                " ",
            )
            .trim()
    }

    private fun vibrar() {
        val vibrator =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager =
                    getSystemService(
                        Context.VIBRATOR_MANAGER_SERVICE,
                    ) as VibratorManager

                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(
                    Context.VIBRATOR_SERVICE,
                ) as Vibrator
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    150,
                    VibrationEffect.DEFAULT_AMPLITUDE,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(150)
        }
    }

    override fun onPartialResult(hypothesis: String) {
        processarHipotese(
            hypothesis,
            "partial",
        )
    }

    override fun onResult(hypothesis: String) {
        processarHipotese(
            hypothesis,
            "text",
        )
    }

    override fun onFinalResult(hypothesis: String) {
        processarHipotese(
            hypothesis,
            "text",
        )
    }

    override fun onError(exception: Exception) {
        Log.e(
            TAG,
            "Erro no reconhecimento: ${exception.message}",
            exception,
        )

        reiniciarReconhecimento()
    }

    override fun onTimeout() {
        Log.d(
            TAG,
            "Reconhecimento finalizado por tempo.",
        )

        reiniciarReconhecimento()
    }

    private fun reiniciarReconhecimento() {
        handler.removeCallbacks(timeoutComando)

        try {
            speechService?.stop()
            speechService?.shutdown()
        } catch (_: Exception) {
        }

        speechService = null

        try {
            recognizer?.close()
        } catch (_: Exception) {
        }

        recognizer = null
        escutando = false
        modo = ModoEscuta.AGUARDANDO_ATIVACAO

        if (deveOuvir) {
            handler.postDelayed({
                iniciarEscuta()
            }, 700)
        }
    }

    private fun criarCanalNotificacao() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel =
            NotificationChannel(
                CHANNEL_ID,
                "NAVESCENCE ativo",
                NotificationManager.IMPORTANCE_LOW,
            )

        channel.description =
            "Mantém o reconhecimento por voz do NAVESCENCE disponível."

        val manager =
            getSystemService(
                NotificationManager::class.java,
            )

        manager.createNotificationChannel(
            channel,
        )
    }

    private fun criarNotificacao(): Notification {
        val abrirApp =
            Intent(
                this,
                MainActivity::class.java,
            )

        val pendingIntent =
            PendingIntent.getActivity(
                this,
                0,
                abrirApp,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE,
            )

        val builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(
                    this,
                    CHANNEL_ID,
                )
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

        return builder
            .setContentTitle(
                "NAVESCENCE ativo",
            )
            .setContentText(
                "Diga NAVE para ativar.",
            )
            .setSmallIcon(
                R.mipmap.ic_launcher,
            )
            .setContentIntent(
                pendingIntent,
            )
            .setOngoing(true)
            .setCategory(
                Notification.CATEGORY_SERVICE,
            )
            .build()
    }

    override fun onInit(status: Int) {
        if (status != TextToSpeech.SUCCESS) {
            Log.e(
                TAG,
                "Falha ao iniciar Text-to-Speech.",
            )

            return
        }

        tts.language =
            Locale(
                "pt",
                "BR",
            )

        tts.setSpeechRate(1.05f)
        tts.setPitch(1.0f)

        ttsPronto = true

        Log.d(
            TAG,
            "Text-to-Speech pronto.",
        )
    }

    override fun onDestroy() {
        deveOuvir = false

        handler.removeCallbacks(timeoutComando)

        try {
            speechService?.stop()
            speechService?.shutdown()
        } catch (_: Exception) {
        }

        speechService = null

        try {
            recognizer?.close()
        } catch (_: Exception) {
        }

        recognizer = null

        try {
            model?.close()
        } catch (_: Exception) {
        }

        model = null

        if (::tts.isInitialized) {
            tts.stop()
            tts.shutdown()
        }

        Log.d(
            TAG,
            "WakeWordService encerrado.",
        )

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}