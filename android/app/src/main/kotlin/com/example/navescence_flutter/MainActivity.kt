package com.example.navescence_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL =
            "navescence/wake_word"
    }

    private lateinit var wakeWordChannel:
        MethodChannel

    private var receiverRegistrado =
        false

    private val wakeWordReceiver =
        object : BroadcastReceiver() {

            override fun onReceive(
                context: Context?,
                intent: Intent?
            ) {
                when (intent?.action) {
                    WakeWordService
                        .ACTION_WAKE_WORD_DETECTADA -> {

                        wakeWordChannel.invokeMethod(
                            "wakeWord",
                            null
                        )
                    }

                    WakeWordService
                        .ACTION_COMANDO_RECONHECIDO -> {

                        val comando =
                            intent.getStringExtra(
                                WakeWordService.EXTRA_COMANDO
                            ) ?: ""

                        if (comando.isNotBlank()) {
                            wakeWordChannel.invokeMethod(
                                "comando",
                                comando
                            )
                        }
                    }

                    WakeWordService
                        .ACTION_TIMEOUT_COMANDO -> {

                        wakeWordChannel.invokeMethod(
                            "timeout",
                            null
                        )
                    }
                }
            }
        }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(
            flutterEngine
        )

        wakeWordChannel =
            MethodChannel(
                flutterEngine
                    .dartExecutor
                    .binaryMessenger,
                CHANNEL
            )

        wakeWordChannel
            .setMethodCallHandler {
                call,
                result ->

                when (call.method) {
                    "iniciar" -> {
                        iniciarWakeWordService()

                        result.success(true)
                    }

                    "ouvir" -> {
                        enviarAcaoServico(
                            WakeWordService
                                .ACTION_OUVIR_NAVE
                        )

                        result.success(true)
                    }

                    "ouvirComando" -> {
                        enviarAcaoServico(
                            WakeWordService
                                .ACTION_OUVIR_COMANDO
                        )

                        result.success(true)
                    }

                    "pausar" -> {
                        enviarAcaoServico(
                            WakeWordService
                                .ACTION_PAUSAR
                        )

                        result.success(true)
                    }

                    "parar" -> {
                        stopService(
                            Intent(
                                this,
                                WakeWordService::class.java
                            )
                        )

                        result.success(true)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }

        registrarReceiver()
    }

    private fun iniciarWakeWordService() {
        val intent =
            Intent(
                this,
                WakeWordService::class.java
            ).apply {
                action =
                    WakeWordService.ACTION_INICIAR
            }

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.O
        ) {
            startForegroundService(
                intent
            )
        } else {
            startService(
                intent
            )
        }
    }

    private fun enviarAcaoServico(
        action: String
    ) {
        val intent =
            Intent(
                this,
                WakeWordService::class.java
            ).apply {
                this.action = action
            }

        startService(intent)
    }

    private fun registrarReceiver() {
        if (receiverRegistrado) {
            return
        }

        val filter =
            IntentFilter().apply {
                addAction(
                    WakeWordService
                        .ACTION_WAKE_WORD_DETECTADA
                )

                addAction(
                    WakeWordService
                        .ACTION_COMANDO_RECONHECIDO
                )

                addAction(
                    WakeWordService
                        .ACTION_TIMEOUT_COMANDO
                )
            }

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.TIRAMISU
        ) {
            registerReceiver(
                wakeWordReceiver,
                filter,
                Context.RECEIVER_NOT_EXPORTED
            )
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(
                wakeWordReceiver,
                filter
            )
        }

        receiverRegistrado = true
    }

    override fun onDestroy() {
        if (receiverRegistrado) {
            try {
                unregisterReceiver(
                    wakeWordReceiver
                )
            } catch (_: Exception) {
            }

            receiverRegistrado = false
        }

        super.onDestroy()
    }
}