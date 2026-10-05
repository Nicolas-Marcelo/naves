package com.example.navescence_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService
import org.vosk.android.StorageService

class WakeWordService : Service(), RecognitionListener {

    companion object {
        private const val TAG = "NAVESCENCE"

        const val ACTION_INICIAR =
            "com.example.navescence_flutter.INICIAR_WAKE_WORD"

        const val ACTION_OUVIR_NAVE =
            "com.example.navescence_flutter.OUVIR_NAVE"

        const val ACTION_OUVIR_COMANDO =
            "com.example.navescence_flutter.OUVIR_COMANDO"

        const val ACTION_DESLIGAR =
            "com.example.navescence_flutter.DESLIGAR_RECONHECIMENTO"

        const val ACTION_PAUSAR =
            "com.example.navescence_flutter.PAUSAR_WAKE_WORD"

        const val ACTION_COMANDO_RECONHECIDO =
            "com.example.navescence_flutter.COMANDO_RECONHECIDO"

        const val ACTION_TIMEOUT_COMANDO =
            "com.example.navescence_flutter.TIMEOUT_COMANDO"

        const val ACTION_WAKE_WORD_DETECTADA =
            "com.example.navescence_flutter.WAKE_WORD_DETECTADA"

        const val EXTRA_COMANDO = "comando"

        private const val CHANNEL_ID = "navescence_voice"
        private const val NOTIFICATION_ID = 7101

        private const val SAMPLE_RATE = 16000.0f

        private const val TEMPO_COMANDO_VAZIO_MS = 3500L
        private const val TEMPO_ESTABILIZACAO_MS = 1300L
        private const val TEMPO_MAXIMO_COMANDO_MS = 7000L
        private const val INTERVALO_MONITOR_MS = 150L

        /*
         * Quanto maior, mais difícil ativar por engano.
         *
         * 0.88 é nosso ponto inicial.
         * Depois podemos ajustar com os testes reais.
         */
        private const val CONFIANCA_MINIMA_WAKE = 0.88

        /*
         * Evita sons extremamente curtos ou falas longas
         * sendo interpretados como "Nave".
         */
        private const val DURACAO_MINIMA_WAKE = 0.18
        private const val DURACAO_MAXIMA_WAKE = 1.40

        /*
         * Evita uma mesma fala disparar novamente logo
         * após uma ativação.
         */
        private const val COOLDOWN_WAKE_MS = 2000L

        /*
         * Wake propositalmente simples.
         *
         * [unk] permite ao recognizer rejeitar áudio que
         * não pertence ao vocabulário desejado.
         */
        private const val GRAMMAR_WAKE =
            """["nave", "[unk]"]"""
    }

    private enum class Modo {
        DESLIGADO,
        WAKE,
        COMANDO
    }

    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var speechService: SpeechService? = null

    @Volatile
    private var modo = Modo.DESLIGADO

    @Volatile
    private var modoDesejado = Modo.DESLIGADO

    @Volatile
    private var comandoParcial = ""

    @Volatile
    private var inicioComando = 0L

    @Volatile
    private var ultimaMudancaComando = 0L

    private var ultimoWakeAceitoEm = 0L

    private var carregandoModelo = false
    private var destruindo = false
    private var trocandoModo = false

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

        handler.post(
            monitorComando
        )

        carregarModelo()
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        when (intent?.action) {
            ACTION_OUVIR_NAVE -> {
                modoDesejado = Modo.WAKE
                aplicarModoDesejado()
            }

            ACTION_OUVIR_COMANDO -> {
                modoDesejado = Modo.COMANDO
                aplicarModoDesejado()
            }

            ACTION_DESLIGAR,
            ACTION_PAUSAR -> {
                modoDesejado = Modo.DESLIGADO
                aplicarModoDesejado()
            }

            ACTION_INICIAR,
            null -> {
                if (model == null) {
                    carregarModelo()
                }
            }
        }

        return START_STICKY
    }

    private fun criarCanalNotificacao() {
        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.O
        ) {
            return
        }

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

    private fun iniciarForeground() {
        val notification =
            NotificationCompat
                .Builder(
                    this,
                    CHANNEL_ID
                )
                .setContentTitle(
                    "NAVESCENCE"
                )
                .setContentText(
                    "Assistente de navegação ativo"
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

                aplicarModoDesejado()
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

    private fun aplicarModoDesejado() {
        if (
            destruindo ||
            trocandoModo
        ) {
            return
        }

        if (model == null) {
            carregarModelo()
            return
        }

        when (modoDesejado) {
            Modo.DESLIGADO ->
                desligarReconhecimento()

            Modo.WAKE ->
                iniciarWake()

            Modo.COMANDO ->
                iniciarComando()
        }
    }

    private fun iniciarWake() {
        if (
            modo == Modo.WAKE &&
            speechService != null &&
            recognizer != null
        ) {
            return
        }

        val currentModel =
            model ?: return

        trocandoModo = true

        try {
            liberarReconhecimento()

            recognizer =
                Recognizer(
                    currentModel,
                    SAMPLE_RATE,
                    GRAMMAR_WAKE
                ).apply {
                    /*
                     * Faz o Vosk devolver:
                     * palavra
                     * confiança
                     * início
                     * fim
                     */
                    setWords(true)
                }

            speechService =
                SpeechService(
                    recognizer,
                    SAMPLE_RATE
                )

            modo = Modo.WAKE

            speechService?.startListening(
                this
            )

            Log.d(
                TAG,
                "MODO -> WAKE RESTRITO SEGURO"
            )
        } catch (exception: Exception) {
            modo = Modo.DESLIGADO

            Log.e(
                TAG,
                "Erro ao iniciar wake word.",
                exception
            )
        } finally {
            trocandoModo = false
        }
    }

    private fun iniciarComando() {
        if (
            modo == Modo.COMANDO &&
            speechService != null &&
            recognizer != null
        ) {
            return
        }

        val currentModel =
            model ?: return

        trocandoModo = true

        try {
            liberarReconhecimento()

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

            comandoParcial = ""

            val agora =
                System.currentTimeMillis()

            inicioComando = agora
            ultimaMudancaComando = agora

            modo = Modo.COMANDO

            speechService?.startListening(
                this,
                TEMPO_MAXIMO_COMANDO_MS.toInt()
            )

            Log.d(
                TAG,
                "MODO -> COMANDO"
            )
        } catch (exception: Exception) {
            modo = Modo.DESLIGADO

            Log.e(
                TAG,
                "Erro ao iniciar reconhecimento de comando.",
                exception
            )

            emitirBroadcast(
                ACTION_TIMEOUT_COMANDO
            )
        } finally {
            trocandoModo = false
        }
    }

    private fun desligarReconhecimento() {
        if (
            modo == Modo.DESLIGADO &&
            speechService == null &&
            recognizer == null
        ) {
            return
        }

        trocandoModo = true

        try {
            liberarReconhecimento()

            modo = Modo.DESLIGADO

            Log.d(
                TAG,
                "MODO -> DESLIGADO"
            )
        } finally {
            trocandoModo = false
        }
    }

    private fun liberarReconhecimento() {
        try {
            speechService?.cancel()
        } catch (_: Exception) {
        }

        try {
            speechService?.shutdown()
        } catch (_: Exception) {
        }

        speechService = null

        try {
            recognizer?.close()
        } catch (_: Exception) {
        }

        recognizer = null

        comandoParcial = ""
        inicioComando = 0L
        ultimaMudancaComando = 0L

        modo = Modo.DESLIGADO
    }

    override fun onPartialResult(
        hypothesis: String?
    ) {
        if (
            destruindo ||
            trocandoModo
        ) {
            return
        }

        val texto =
            extrairCampo(
                hypothesis,
                "partial"
            )

        if (texto.isEmpty()) {
            return
        }

        when (modo) {
            Modo.WAKE -> {
                /*
                 * MUITO IMPORTANTE:
                 *
                 * resultado parcial nunca mais ativa
                 * o assistente.
                 *
                 * Serve apenas para diagnóstico.
                 */
                Log.d(
                    TAG,
                    "WAKE [partial ignorado]: $texto"
                )
            }

            Modo.COMANDO -> {
                Log.d(
                    TAG,
                    "COMANDO [partial]: $texto"
                )

                registrarComandoParcial(
                    texto
                )
            }

            Modo.DESLIGADO -> Unit
        }
    }

    override fun onResult(
        hypothesis: String?
    ) {
        if (
            destruindo ||
            trocandoModo
        ) {
            return
        }

        when (modo) {
            Modo.WAKE -> {
                avaliarWakeFinal(
                    hypothesis
                )
            }

            Modo.COMANDO -> {
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
                    "COMANDO [text]: $texto"
                )

                enviarComando(
                    texto
                )
            }

            Modo.DESLIGADO -> Unit
        }
    }

    override fun onFinalResult(
        hypothesis: String?
    ) {
        if (
            destruindo ||
            trocandoModo
        ) {
            return
        }

        when (modo) {
            Modo.WAKE -> {
                avaliarWakeFinal(
                    hypothesis
                )
            }

            Modo.COMANDO -> {
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
                    "COMANDO [final]: $texto"
                )

                enviarComando(
                    texto
                )
            }

            Modo.DESLIGADO -> Unit
        }
    }

    private fun avaliarWakeFinal(
        hypothesis: String?
    ) {
        if (
            modo != Modo.WAKE ||
            hypothesis.isNullOrBlank()
        ) {
            return
        }

        val avaliacao =
            analisarWake(
                hypothesis
            )

        if (avaliacao == null) {
            Log.d(
                TAG,
                "WAKE rejeitado: resultado incompatível."
            )

            return
        }

        Log.d(
            TAG,
            "WAKE candidato: " +
                "texto=${avaliacao.texto} " +
                "conf=${"%.2f".format(avaliacao.confianca)} " +
                "dur=${"%.2f".format(avaliacao.duracao)}s"
        )

        if (
            avaliacao.confianca <
            CONFIANCA_MINIMA_WAKE
        ) {
            Log.d(
                TAG,
                "WAKE REJEITADO -> confiança baixa."
            )

            return
        }

        if (
            avaliacao.duracao <
            DURACAO_MINIMA_WAKE ||
            avaliacao.duracao >
            DURACAO_MAXIMA_WAKE
        ) {
            Log.d(
                TAG,
                "WAKE REJEITADO -> duração fora da faixa."
            )

            return
        }

        val agora =
            System.currentTimeMillis()

        if (
            ultimoWakeAceitoEm > 0 &&
            agora - ultimoWakeAceitoEm <
            COOLDOWN_WAKE_MS
        ) {
            Log.d(
                TAG,
                "WAKE REJEITADO -> cooldown."
            )

            return
        }

        ultimoWakeAceitoEm =
            agora

        palavraChaveDetectada()
    }

    private fun analisarWake(
        hypothesis: String
    ): WakeAvaliacao? {
        return try {
            val json =
                JSONObject(
                    hypothesis
                )

            val texto =
                normalizar(
                    json.optString(
                        "text",
                        ""
                    )
                )

            /*
             * Somente exatamente "nave".
             */
            if (texto != "nave") {
                return null
            }

            val resultado =
                json.optJSONArray(
                    "result"
                ) ?: return null

            /*
             * Queremos exatamente uma palavra.
             *
             * Se houver mais palavras, não era
             * nosso wake limpo.
             */
            if (resultado.length() != 1) {
                return null
            }

            val palavra =
                resultado.getJSONObject(
                    0
                )

            val palavraReconhecida =
                normalizar(
                    palavra.optString(
                        "word",
                        ""
                    )
                )

            if (
                palavraReconhecida !=
                "nave"
            ) {
                return null
            }

            val confianca =
                palavra.optDouble(
                    "conf",
                    0.0
                )

            val inicio =
                palavra.optDouble(
                    "start",
                    0.0
                )

            val fim =
                palavra.optDouble(
                    "end",
                    0.0
                )

            val duracao =
                fim - inicio

            WakeAvaliacao(
                texto = texto,
                confianca = confianca,
                duracao = duracao
            )
        } catch (exception: Exception) {
            Log.e(
                TAG,
                "Erro ao analisar wake.",
                exception
            )

            null
        }
    }

    private fun palavraChaveDetectada() {
        if (
            modo != Modo.WAKE ||
            trocandoModo
        ) {
            return
        }

        Log.d(
            TAG,
            "NAVE CONFIRMADO!"
        )

        modoDesejado =
            Modo.DESLIGADO

        desligarReconhecimento()

        FeedbackTatil.executar(
            this,
            "ativacao"
        )

        emitirBroadcast(
            ACTION_WAKE_WORD_DETECTADA
        )
    }

    private fun registrarComandoParcial(
        texto: String
    ) {
        val normalizado =
            normalizar(
                texto
            )

        if (normalizado.isEmpty()) {
            return
        }

        if (
            normalizado !=
            comandoParcial
        ) {
            comandoParcial =
                normalizado

            ultimaMudancaComando =
                System.currentTimeMillis()
        }
    }

    private fun verificarTempoComando() {
        if (
            modo != Modo.COMANDO ||
            trocandoModo
        ) {
            return
        }

        val agora =
            System.currentTimeMillis()

        val tempoTotal =
            agora -
            inicioComando

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
            agora -
            ultimaMudancaComando

        if (
            tempoSemMudanca >=
            TEMPO_ESTABILIZACAO_MS
        ) {
            enviarComando(
                comandoParcial
            )
        }
    }

    private fun enviarComando(
        texto: String
    ) {
        if (
            modo != Modo.COMANDO ||
            trocandoModo
        ) {
            return
        }

        val comando =
            normalizar(
                texto
            )

        if (comando.isEmpty()) {
            timeoutComando()
            return
        }

        Log.d(
            TAG,
            "COMANDO CAPTURADO: $comando"
        )

        modoDesejado =
            Modo.DESLIGADO

        desligarReconhecimento()

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

        sendBroadcast(
            intent
        )
    }

    private fun timeoutComando() {
        if (
            modo != Modo.COMANDO ||
            trocandoModo
        ) {
            return
        }

        Log.d(
            TAG,
            "Timeout de comando."
        )

        modoDesejado =
            Modo.DESLIGADO

        desligarReconhecimento()

        emitirBroadcast(
            ACTION_TIMEOUT_COMANDO
        )
    }

    private fun normalizar(
        texto: String
    ): String {
        return texto
            .lowercase()
            .replace("á", "a")
            .replace("à", "a")
            .replace("â", "a")
            .replace("ã", "a")
            .replace("é", "e")
            .replace("ê", "e")
            .replace("í", "i")
            .replace("ó", "o")
            .replace("ô", "o")
            .replace("õ", "o")
            .replace("ú", "u")
            .replace("ç", "c")
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
        if (
            json.isNullOrBlank()
        ) {
            return ""
        }

        return try {
            JSONObject(
                json
            )
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
            Intent(
                action
            ).apply {
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
        if (
            destruindo ||
            trocandoModo
        ) {
            return
        }

        val modoErro =
            modo

        Log.e(
            TAG,
            "Erro no reconhecimento em $modoErro.",
            exception
        )

        modoDesejado =
            if (
                modoErro ==
                Modo.WAKE
            ) {
                Modo.WAKE
            } else {
                Modo.DESLIGADO
            }

        desligarReconhecimento()

        if (
            modoErro ==
            Modo.COMANDO
        ) {
            emitirBroadcast(
                ACTION_TIMEOUT_COMANDO
            )
        }

        if (
            modoErro ==
            Modo.WAKE
        ) {
            handler.postDelayed(
                {
                    aplicarModoDesejado()
                },
                700L
            )
        }
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

    override fun onDestroy() {
        destruindo = true

        handler.removeCallbacks(
            monitorComando
        )

        modoDesejado =
            Modo.DESLIGADO

        liberarReconhecimento()

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

    private data class WakeAvaliacao(
        val texto: String,
        val confianca: Double,
        val duracao: Double
    )
}