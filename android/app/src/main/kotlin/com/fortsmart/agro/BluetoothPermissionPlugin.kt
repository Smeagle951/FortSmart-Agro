package com.fortsmart.agro

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Plugin nativo para gerenciar permissões Bluetooth
 */
class BluetoothPermissionPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var bluetoothHelper: BluetoothPermissionHelper? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bluetooth_permission")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "hasAllPermissions" -> {
                val hasPermissions = bluetoothHelper?.hasAllBluetoothPermissions() ?: false
                result.success(hasPermissions)
            }
            "requestPermissions" -> {
                bluetoothHelper?.requestBluetoothPermissions()
                result.success(null)
            }
            "isBluetoothEnabled" -> {
                val isEnabled = bluetoothHelper?.isBluetoothEnabled() ?: false
                result.success(isEnabled)
            }
            "requestEnableBluetooth" -> {
                bluetoothHelper?.requestEnableBluetooth()
                result.success(null)
            }
            "supportsBluetoothLE" -> {
                val supportsLE = bluetoothHelper?.supportsBluetoothLE() ?: false
                result.success(supportsLE)
            }
            "supportsBluetooth" -> {
                val supports = bluetoothHelper?.supportsBluetooth() ?: false
                result.success(supports)
            }
            "getBluetoothInfo" -> {
                val info = bluetoothHelper?.getBluetoothInfo() ?: emptyMap<String, Any?>()
                result.success(info)
            }
            "getPairedDevices" -> {
                val pairedDevices = bluetoothHelper?.getPairedDevices() ?: emptyList<Map<String, Any?>>()
                result.success(pairedDevices)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        bluetoothHelper = BluetoothPermissionHelper(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        bluetoothHelper = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        bluetoothHelper = BluetoothPermissionHelper(binding.activity)
    }

    override fun onDetachedFromActivity() {
        activity = null
        bluetoothHelper = null
    }
}
