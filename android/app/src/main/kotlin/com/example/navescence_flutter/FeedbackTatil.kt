package com.example.navescence_flutter

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

object FeedbackTatil {

    private const val TAG =
        "NAVESCENCE"

    fun executar(
        context: Context,
        tipo: String
    ) {
        try {
            val vibrator =
                obterVibrador(
                    context
                )

            if (!vibrator.hasVibrator()) {
                return
            }

            val padrao =
                obterPadrao(
                    tipo
                )

            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.O
            ) {
                val effect =
                    VibrationEffect.createWaveform(
                        padrao.tempos,
                        padrao.amplitudes,
                        -1
                    )

                vibrarComAtributos(
                    vibrator,
                    effect
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(
                    padrao.tempos,
                    -1
                )
            }

            Log.d(
                TAG,
                "Feedback tátil: $tipo"
            )
        } catch (exception: Exception) {
            Log.e(
                TAG,
                "Erro no feedback tátil.",
                exception
            )
        }
    }

    private fun obterVibrador(
        context: Context
    ): Vibrator {
        return if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.S
        ) {
            val manager =
                context.getSystemService(
                    Context.VIBRATOR_MANAGER_SERVICE
                ) as VibratorManager

            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(
                Context.VIBRATOR_SERVICE
            ) as Vibrator
        }
    }

    private fun vibrarComAtributos(
        vibrator: Vibrator,
        effect: VibrationEffect
    ) {
        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.TIRAMISU
        ) {
            val attributes =
                VibrationAttributes
                    .Builder()
                    .setUsage(
                        VibrationAttributes
                            .USAGE_ACCESSIBILITY
                    )
                    .build()

            vibrator.vibrate(
                effect,
                attributes
            )

            return
        }

        val attributes =
            AudioAttributes
                .Builder()
                .setUsage(
                    AudioAttributes
                        .USAGE_ASSISTANCE_ACCESSIBILITY
                )
                .setContentType(
                    AudioAttributes
                        .CONTENT_TYPE_SONIFICATION
                )
                .build()

        vibrator.vibrate(
            effect,
            attributes
        )
    }

    private fun obterPadrao(
        tipo: String
    ): PadraoVibracao {
        return when (tipo) {
            "ativacao" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        130
                    ),
                    intArrayOf(
                        0,
                        210
                    )
                )

            "ouvindo" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        70,
                        90,
                        70
                    ),
                    intArrayOf(
                        0,
                        190,
                        0,
                        190
                    )
                )

            "sucesso" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        180
                    ),
                    intArrayOf(
                        0,
                        190
                    )
                )

            "erro" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        220,
                        120,
                        220
                    ),
                    intArrayOf(
                        0,
                        230,
                        0,
                        230
                    )
                )

            "frente" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        320
                    ),
                    intArrayOf(
                        0,
                        210
                    )
                )

            "esquerda" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        300,
                        120,
                        90
                    ),
                    intArrayOf(
                        0,
                        220,
                        0,
                        180
                    )
                )

            "direita" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        90,
                        120,
                        300
                    ),
                    intArrayOf(
                        0,
                        180,
                        0,
                        220
                    )
                )

            "recalculo" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        80,
                        80,
                        80,
                        120,
                        260
                    ),
                    intArrayOf(
                        0,
                        170,
                        0,
                        170,
                        0,
                        230
                    )
                )

            "chegada" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        100,
                        80,
                        100,
                        80,
                        100
                    ),
                    intArrayOf(
                        0,
                        210,
                        0,
                        210,
                        0,
                        210
                    )
                )

            "sinalPerdido" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        250,
                        150,
                        250,
                        150,
                        250
                    ),
                    intArrayOf(
                        0,
                        240,
                        0,
                        240,
                        0,
                        240
                    )
                )

            "cancelado" ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        180,
                        100,
                        70
                    ),
                    intArrayOf(
                        0,
                        210,
                        0,
                        150
                    )
                )

            else ->
                PadraoVibracao(
                    longArrayOf(
                        0,
                        100
                    ),
                    intArrayOf(
                        0,
                        180
                    )
                )
        }
    }

    private data class PadraoVibracao(
        val tempos: LongArray,
        val amplitudes: IntArray
    )
}