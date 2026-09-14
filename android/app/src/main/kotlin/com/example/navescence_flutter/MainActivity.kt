package com.example.navescence_flutter

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val REQUEST_PERMISSOES = 731
        private const val CHANNEL_WAKE_WORD = "navescence/wake_word"
        private const val TAG = "NAVESCENCE"
    }

    private var canalWakeWord: MethodChannel? = null
    private var receiverRegistrado = false

    private val comandoReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != WakeWordService.ACTION_COMANDO_RECONHECIDO) return

            val comando = intent.getStringExtra(WakeWordService.EXTRA_COMANDO)?.trim()

            if (comando.isNullOrEmpty()) return

            Log.d(TAG, "Enviando comando para Flutter: $comando")

            canalWakeWord?.invokeMethod(
                "comandoReconhecido",
                comando,
            )
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        verificarPermissoes()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        canalWakeWord = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_WAKE_WORD,
        )

        canalWakeWord?.setMethodCallHandler { call, result ->
            when (call.method) {
                "iniciar" -> {
                    iniciarServico()
                    result.success(true)
                }

                "ouvir" -> {
                    enviarAcaoServico(
                        WakeWordService.ACTION_OUVIR,
                    )

                    result.success(true)
                }

                "pausar" -> {
                    enviarAcaoServico(
                        WakeWordService.ACTION_PAUSAR,
                    )

                    result.success(true)
                }

                "parar" -> {
                    enviarAcaoServico(
                        WakeWordService.ACTION_PARAR,
                    )

                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        registrarReceiver()
    }

    private fun registrarReceiver() {
        if (receiverRegistrado) return

        val filtro = IntentFilter(
            WakeWordService.ACTION_COMANDO_RECONHECIDO,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(
                comandoReceiver,
                filtro,
                Context.RECEIVER_NOT_EXPORTED,
            )
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(
                comandoReceiver,
                filtro,
            )
        }

        receiverRegistrado = true
    }

    private fun verificarPermissoes() {
        val permissoes = mutableListOf<String>()

        if (
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            permissoes.add(
                Manifest.permission.RECORD_AUDIO,
            )
        }

        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            permissoes.add(
                Manifest.permission.POST_NOTIFICATIONS,
            )
        }

        if (permissoes.isEmpty()) {
            iniciarServico()
            return
        }

        requestPermissions(
            permissoes.toTypedArray(),
            REQUEST_PERMISSOES,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults,
        )

        if (requestCode != REQUEST_PERMISSOES) return

        val microfoneAutorizado =
            checkSelfPermission(
                Manifest.permission.RECORD_AUDIO,
            ) == PackageManager.PERMISSION_GRANTED

        if (microfoneAutorizado) {
            iniciarServico()
        }
    }

    private fun iniciarServico() {
        val intent = Intent(
            this,
            WakeWordService::class.java,
        ).apply {
            action = WakeWordService.ACTION_INICIAR
        }

        ContextCompat.startForegroundService(
            this,
            intent,
        )
    }

    private fun enviarAcaoServico(acao: String) {
        val intent = Intent(
            this,
            WakeWordService::class.java,
        ).apply {
            action = acao
        }

        startService(intent)
    }

    override fun onDestroy() {
        if (receiverRegistrado) {
            try {
                unregisterReceiver(
                    comandoReceiver,
                )
            } catch (_: Exception) {
            }

            receiverRegistrado = false
        }

        canalWakeWord?.setMethodCallHandler(null)
        canalWakeWord = null

        super.onDestroy()
    }
}