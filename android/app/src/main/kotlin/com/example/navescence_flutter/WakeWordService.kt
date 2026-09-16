package com.example.navescence_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService
import org.vosk.android.StorageService
import java.text.Normalizer
import java.util.Locale

class WakeWordService : Service(), RecognitionListener {

    companion object {
        private const val TAG = "NAVESCENCE"

        const val ACTION_INICIAR =
            "com.example.navescence_flutter.INICIAR_WAKE_WORD"

        const val ACTION_OUVIR_NAVE =
            "com.example.navescence_flutter.OUVIR_NAVE"

        const val ACTION_OUVIR_COMANDO =
            "com.example.navescence_flutter.OUVIR_COMANDO"

        const val ACTION_PAUSAR =
            "com.example.navescence_flutter.PAUSAR_WAKE_WORD"

        const val ACTION_COMANDO_RECONHECIDO =
            "com.example.navescence_flutter.COMANDO_RECONHECIDO"

        const val ACTION_TIMEOUT_COMANDO =
            "com.example.navescence_flutter.TIMEOUT_COMANDO"

        const val ACTION_WAKE_WORD_DETECTADA =
            "com.example.navescence_flutter.WAKE_WORD_DETECTADA"

        const val EXTRA_COMANDO = "comando"

        private const val CHANNEL_ID =
            "navescence_voice"

        private const val NOTIFICATION_ID = 7101

        private const val SAMPLE_RATE = 16000.0f

        private const val TEMPO_COMANDO_VAZIO_MS = 2500L
        private const val TEMPO_ESTABILIZACAO_MS = 1500L
        private const val TEMPO_MAXIMO_COMANDO_MS = 6500L
        private const val INTERVALO_MONITOR_MS = 150L

        private const val DURACAO_VIBRACAO_MS = 140L
    }

    private enum class Modo {
        NAVE,
        COMANDO,
        PAUSADO
    }

    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var speechService: SpeechService? = null

    @Volatile
    private var modo = Modo.NAVE

    @Volatile
    private var comandoParcial = ""

    @Volatile
    private var inicioComando = 0L

    @Volatile
    private var ultimaMudancaComando = 0L

    private var destruindo = false
    private var carregandoModelo = false

    private val handler =
        Handler(Looper.getMainLooper())

    private val monitorComando =
        object : Runnable {

            override fun run() {
                verificarTempoComando()

                if (!destruindo) {
                    handler.postDelayed(
                        this,
                        INTERVALO_MONITOR_MS
                    )
                }
            }
        }

    override fun onCreate() {
        super.onCreate()

        criarCanalNotificacao()
        iniciarForeground()

        handler.post(monitorComando)

        carregarModelo()
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        when (intent?.action) {
            ACTION_OUVIR_NAVE -> {
                continuarEscuta()
                voltarParaNave()
            }

            ACTION_OUVIR_COMANDO -> {
                continuarEscuta()

                ativarModoComando(
                    emitirWakeWord = true
                )
            }

            ACTION_PAUSAR -> {
                modo = Modo.PAUSADO

                speechService?.setPause(true)

                Log.d(
                    TAG,
                    "Reconhecimento pausado."
                )
            }

            ACTION_INICIAR,
            null -> {
                continuarEscuta()

                if (model == null) {
                    carregarModelo()
                } else if (speechService == null) {
                    iniciarReconhecimento()
                }
            }
        }

        return START_STICKY
    }

    private fun criarCanalNotificacao() {
        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.O
        ) {
            val manager =
                getSystemService(
                    NotificationManager::class.java
                )

            val channel =
                NotificationChannel(
                    CHANNEL_ID,
                    "NAVESCENCE Voz",
                    NotificationManager.IMPORTANCE_LOW
                )

            channel.description =
                "Reconhecimento de voz do NAVESCENCE"

            manager.createNotificationChannel(
                channel
            )
        }
    }

    private fun iniciarForeground() {
        val notification =
            NotificationCompat.Builder(
                this,
                CHANNEL_ID
            )
                .setContentTitle(
                    "NAVESCENCE"
                )
                .setContentText(
                    "Reconhecimento de voz ativo"
                )
                .setSmallIcon(
                    android.R.drawable.ic_btn_speak_now
                )
                .setOngoing(true)
                .build()

        startForeground(
            NOTIFICATION_ID,
            notification
        )
    }

    private fun carregarModelo() {
        if (
            carregandoModelo ||
            model != null ||
            destruindo
        ) {
            return
        }

        carregandoModelo = true

        Log.d(
            TAG,
            "Carregando modelo Vosk..."
        )

        StorageService.unpack(
            this,
            "model-pt",
            "model-pt",
            { loadedModel ->
                carregandoModelo = false
                model = loadedModel

                Log.d(
                    TAG,
                    "Modelo Vosk carregado."
                )

                iniciarReconhecimento()
            },
            { exception ->
                carregandoModelo = false

                Log.e(
                    TAG,
                    "Erro ao carregar modelo Vosk.",
                    exception
                )
            }
        )
    }

    private fun iniciarReconhecimento() {
        if (
            destruindo ||
            speechService != null
        ) {
            return
        }

        val currentModel =
            model ?: return

        try {
            recognizer =
                Recognizer(
                    currentModel,
                    SAMPLE_RATE
                )

            speechService =
                SpeechService(
                    recognizer,
                    SAMPLE_RATE
                )

            speechService?.startListening(
                this
            )

            modo = Modo.NAVE

            Log.d(
                TAG,
                "Aguardando NAVE..."
            )
        } catch (exception: Exception) {
            Log.e(
                TAG,
                "Erro ao iniciar reconhecimento.",
                exception
            )
        }
    }

    private fun continuarEscuta() {
        speechService?.setPause(false)
    }

    override fun onPartialResult(
        hypothesis: String?
    ) {
        val texto =
            extrairCampo(
                hypothesis,
                "partial"
            )

        if (texto.isEmpty()) {
            return
        }

        Log.d(
            TAG,
            "VOSK [partial]: $texto"
        )

        when (modo) {
            Modo.NAVE -> {
                if (ehPalavraChave(texto)) {
                    ativarModoComando()
                }
            }

            Modo.COMANDO -> {
                registrarComandoParcial(
                    texto
                )
            }

            Modo.PAUSADO -> Unit
        }
    }

    override fun onResult(
        hypothesis: String?
    ) {
        val texto =
            extrairCampo(
                hypothesis,
                "text"
            )

        if (texto.isEmpty()) {
            return
        }

        Log.d(
            TAG,
            "VOSK [text]: $texto"
        )

        processarResultadoFinal(
            texto
        )
    }

    override fun onFinalResult(
        hypothesis: String?
    ) {
        if (destruindo) return

        val texto =
            extrairCampo(
                hypothesis,
                "text"
            )

        if (texto.isEmpty()) {
            return
        }

        Log.d(
            TAG,
            "VOSK [final]: $texto"
        )

        processarResultadoFinal(
            texto
        )
    }

    private fun processarResultadoFinal(
        texto: String
    ) {
        when (modo) {
            Modo.NAVE -> {
                if (ehPalavraChave(texto)) {
                    ativarModoComando()
                }
            }

            Modo.COMANDO -> {
                val comando =
                    removerPalavraChave(
                        texto
                    )

                if (comando.isNotEmpty()) {
                    enviarComando(
                        comando
                    )
                }
            }

            Modo.PAUSADO -> Unit
        }
    }

    private fun ativarModoComando(
        emitirWakeWord: Boolean = true
    ) {
        if (modo == Modo.COMANDO) {
            return
        }

        modo = Modo.COMANDO

        comandoParcial = ""

        val agora =
            System.currentTimeMillis()

        inicioComando = agora
        ultimaMudancaComando = agora

        speechService?.reset()

        Log.d(
            TAG,
            "PALAVRA-CHAVE DETECTADA!"
        )

        vibrarInicioEscuta()

        if (emitirWakeWord) {
            emitirBroadcast(
                ACTION_WAKE_WORD_DETECTADA
            )
        }

        Log.d(
            TAG,
            "Aguardando comando..."
        )
    }

    private fun vibrarInicioEscuta() {
        try {
            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.S
            ) {
                val vibratorManager =
                    getSystemService(
                        Context.VIBRATOR_MANAGER_SERVICE
                    ) as VibratorManager

                val vibrator =
                    vibratorManager.defaultVibrator

                vibrator.vibrate(
                    VibrationEffect.createOneShot(
                        DURACAO_VIBRACAO_MS,
                        VibrationEffect.DEFAULT_AMPLITUDE
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                val vibrator =
                    getSystemService(
                        Context.VIBRATOR_SERVICE
                    ) as Vibrator

                if (
                    Build.VERSION.SDK_INT >=
                    Build.VERSION_CODES.O
                ) {
                    vibrator.vibrate(
                        VibrationEffect.createOneShot(
                            DURACAO_VIBRACAO_MS,
                            VibrationEffect.DEFAULT_AMPLITUDE
                        )
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(
                        DURACAO_VIBRACAO_MS
                    )
                }
            }

            Log.d(
                TAG,
                "Vibração de escuta executada."
            )
        } catch (exception: Exception) {
            Log.e(
                TAG,
                "Falha ao executar vibração.",
                exception
            )
        }
    }

    private fun registrarComandoParcial(
        texto: String
    ) {
        val comando =
            removerPalavraChave(
                texto
            )

        if (comando.isEmpty()) {
            return
        }

        if (comando != comandoParcial) {
            comandoParcial = comando

            ultimaMudancaComando =
                System.currentTimeMillis()
        }
    }

    private fun verificarTempoComando() {
        if (modo != Modo.COMANDO) {
            return
        }

        val agora =
            System.currentTimeMillis()

        val tempoTotal =
            agora - inicioComando

        if (comandoParcial.isEmpty()) {
            if (
                tempoTotal >=
                TEMPO_COMANDO_VAZIO_MS
            ) {
                timeoutComando()
            }

            return
        }

        val tempoSemMudanca =
            agora - ultimaMudancaComando

        if (
            tempoSemMudanca >=
            TEMPO_ESTABILIZACAO_MS
        ) {
            enviarComando(
                comandoParcial
            )

            return
        }

        if (
            tempoTotal >=
            TEMPO_MAXIMO_COMANDO_MS
        ) {
            enviarComando(
                comandoParcial
            )
        }
    }

    private fun enviarComando(
        texto: String
    ) {
        val comando =
            normalizar(texto)

        if (comando.isEmpty()) {
            timeoutComando()
            return
        }

        Log.d(
            TAG,
            "COMANDO CAPTURADO: $comando"
        )

        val intent =
            Intent(
                ACTION_COMANDO_RECONHECIDO
            ).apply {
                setPackage(
                    packageName
                )

                putExtra(
                    EXTRA_COMANDO,
                    comando
                )
            }

        sendBroadcast(intent)

        Log.d(
            TAG,
            "Enviando comando para Flutter: $comando"
        )

        voltarParaNave()
    }

    private fun timeoutComando() {
        Log.d(
            TAG,
            "Timeout de comando."
        )

        emitirBroadcast(
            ACTION_TIMEOUT_COMANDO
        )

        voltarParaNave()
    }

    private fun voltarParaNave() {
        if (modo == Modo.PAUSADO) {
            return
        }

        modo = Modo.NAVE

        comandoParcial = ""
        inicioComando = 0L
        ultimaMudancaComando = 0L

        speechService?.reset()

        Log.d(
            TAG,
            "Aguardando NAVE..."
        )
    }

    private fun ehPalavraChave(
        texto: String
    ): Boolean {
        val normalizado =
            normalizar(texto)

        return normalizado == "nave" ||
            normalizado == "naves"
    }

    private fun removerPalavraChave(
        texto: String
    ): String {
        var resultado =
            normalizar(texto)

        resultado =
            resultado.replaceFirst(
                Regex(
                    """^(naves|nave)\b\s*"""
                ),
                ""
            )

        return resultado.trim()
    }

    private fun normalizar(
        texto: String
    ): String {
        val semAcentos =
            Normalizer.normalize(
                texto,
                Normalizer.Form.NFD
            )
                .replace(
                    Regex("\\p{M}+"),
                    ""
                )

        return semAcentos
            .lowercase(
                Locale.ROOT
            )
            .replace(
                Regex(
                    "[^a-z0-9\\s]"
                ),
                " "
            )
            .replace(
                Regex("\\s+"),
                " "
            )
            .trim()
    }

    private fun extrairCampo(
        json: String?,
        campo: String
    ): String {
        if (json.isNullOrBlank()) {
            return ""
        }

        return try {
            JSONObject(json)
                .optString(
                    campo,
                    ""
                )
                .trim()
        } catch (_: Exception) {
            ""
        }
    }

    private fun emitirBroadcast(
        action: String
    ) {
        val intent =
            Intent(action).apply {
                setPackage(
                    packageName
                )
            }

        sendBroadcast(
            intent
        )
    }

    override fun onError(
        exception: Exception?
    ) {
        if (destruindo) return

        Log.e(
            TAG,
            "Erro no reconhecimento Vosk.",
            exception
        )

        if (
            modo ==
            Modo.COMANDO
        ) {
            emitirBroadcast(
                ACTION_TIMEOUT_COMANDO
            )
        }

        modo = Modo.NAVE

        reiniciarReconhecimento()
    }

    override fun onTimeout() {
        if (
            !destruindo &&
            modo ==
                Modo.COMANDO
        ) {
            timeoutComando()
        }
    }

    private fun reiniciarReconhecimento() {
        handler.postDelayed(
            {
                if (destruindo) {
                    return@postDelayed
                }

                try {
                    speechService
                        ?.cancel()

                    speechService
                        ?.shutdown()
                } catch (_: Exception) {
                }

                speechService = null

                try {
                    recognizer
                        ?.close()
                } catch (_: Exception) {
                }

                recognizer = null

                iniciarReconhecimento()
            },
            500L
        )
    }

    override fun onDestroy() {
        destruindo = true

        handler.removeCallbacks(
            monitorComando
        )

        try {
            speechService
                ?.cancel()

            speechService
                ?.shutdown()
        } catch (_: Exception) {
        }

        speechService = null

        try {
            recognizer
                ?.close()
        } catch (_: Exception) {
        }

        recognizer = null

        try {
            model?.close()
        } catch (_: Exception) {
        }

        model = null

        super.onDestroy()
    }

    override fun onBind(
        intent: Intent?
    ): IBinder? {
        return null
    }
}