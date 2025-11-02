package com.fortsmart.agro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "bluetooth_permission"
    private lateinit var bluetoothPlugin: BluetoothPermissionPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Registra o plugin Bluetooth
        bluetoothPlugin = BluetoothPermissionPlugin()
        flutterEngine.plugins.add(bluetoothPlugin)
    }
}

