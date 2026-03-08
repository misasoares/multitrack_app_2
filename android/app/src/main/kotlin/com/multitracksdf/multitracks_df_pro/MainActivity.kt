package com.multitracksdf.multitracks_df_pro

import io.flutter.embedding.android.FlutterActivity
import android.media.midi.*
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    // Declaração da função nativa no C++ (bridge.cpp)
    external fun onNativeMidiNoteOn(note: Int)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupMidiBypass()
    }

    private fun setupMidiBypass() {
        val midiManager = getSystemService(Context.MIDI_SERVICE) as MidiManager
        // Procura dispositivos MIDI conectados (Bluetooth ou USB)
        val infos = midiManager.devices
        if (infos.isNotEmpty()) {
            // Tentamos abrir o primeiro dispositivo disponível
            midiManager.openDevice(infos[0], { device ->
                if (device != null) {
                    val outputPort = device.openOutputPort(0)
                    outputPort?.connect(object : MidiReceiver() {
                        override fun onSend(msg: ByteArray?, offset: Int, count: Int, timestamp: Long) {
                            if (msg != null && count >= 3) {
                                val status = msg[offset].toInt() and 0xFF
                                finalNoteOn(msg, offset, count)
                            }
                        }

                        private fun finalNoteOn(msg: ByteArray, offset: Int, count: Int) {
                             val status = msg[offset].toInt() and 0xFF
                             val note = msg[offset + 1].toInt() and 0x7F
                             val velocity = msg[offset + 2].toInt() and 0x7F
                             
                             // Intercepta Note On no Canal 1 (0x90 a 0x9F) e Velocity > 0
                             if (status in 0x90..0x9F && velocity > 0) {
                                 onNativeMidiNoteOn(note)
                             }
                        }
                    })
                }
            }, Handler(Looper.getMainLooper()))
        }
    }
}
