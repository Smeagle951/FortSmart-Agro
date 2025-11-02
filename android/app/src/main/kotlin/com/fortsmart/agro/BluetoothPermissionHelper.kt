package com.fortsmart.agro

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * Helper class para gerenciar permissões Bluetooth no Android
 */
class BluetoothPermissionHelper(private val activity: Activity) {
    
    companion object {
        const val REQUEST_BLUETOOTH_PERMISSIONS = 1001
        const val REQUEST_ENABLE_BLUETOOTH = 1002
        
        // Lista de permissões necessárias para diferentes versões do Android
        val BLUETOOTH_PERMISSIONS = arrayOf(
            Manifest.permission.BLUETOOTH,
            Manifest.permission.BLUETOOTH_ADMIN,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
        
        val BLUETOOTH_PERMISSIONS_ANDROID_12_PLUS = arrayOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_ADVERTISE
        )
    }
    
    /**
     * Verifica se todas as permissões Bluetooth estão concedidas
     */
    fun hasAllBluetoothPermissions(): Boolean {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            BLUETOOTH_PERMISSIONS_ANDROID_12_PLUS
        } else {
            BLUETOOTH_PERMISSIONS
        }
        
        return permissions.all { permission ->
            ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    /**
     * Solicita permissões Bluetooth necessárias
     */
    fun requestBluetoothPermissions() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            BLUETOOTH_PERMISSIONS_ANDROID_12_PLUS
        } else {
            BLUETOOTH_PERMISSIONS
        }
        
        val permissionsToRequest = permissions.filter { permission ->
            ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                activity,
                permissionsToRequest.toTypedArray(),
                REQUEST_BLUETOOTH_PERMISSIONS
            )
        }
    }
    
    /**
     * Verifica se o Bluetooth está habilitado
     */
    fun isBluetoothEnabled(): Boolean {
        val bluetoothManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter
        return bluetoothAdapter?.isEnabled == true
    }
    
    /**
     * Solicita para habilitar o Bluetooth
     */
    fun requestEnableBluetooth() {
        val bluetoothManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter
        
        if (bluetoothAdapter != null && !bluetoothAdapter.isEnabled) {
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            if (ActivityCompat.checkSelfPermission(
                    activity,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                activity.startActivityForResult(enableBtIntent, REQUEST_ENABLE_BLUETOOTH)
            }
        }
    }
    
    /**
     * Verifica se o dispositivo suporta Bluetooth Low Energy
     */
    fun supportsBluetoothLE(): Boolean {
        val bluetoothManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter
        return bluetoothAdapter?.bluetoothLeScanner != null
    }
    
    /**
     * Verifica se o dispositivo suporta Bluetooth
     */
    fun supportsBluetooth(): Boolean {
        val bluetoothManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        return bluetoothManager.adapter != null
    }
    
    /**
     * Obtém dispositivos Bluetooth pareados
     */
    fun getPairedDevices(): List<Map<String, Any?>> {
        val bluetoothManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter
        
        if (bluetoothAdapter == null) return emptyList()
        
        val pairedDevices = bluetoothAdapter.bondedDevices
        return pairedDevices.map { device ->
            mapOf<String, Any?>(
                "name" to (device.name ?: "Unknown"),
                "address" to device.address,
                "type" to device.type,
                "bondState" to device.bondState,
                "uuids" to (device.uuids?.map { it.toString() } ?: emptyList<String>())
            )
        }.toList()
    }

    /**
     * Obtém informações do dispositivo Bluetooth
     */
    fun getBluetoothInfo(): Map<String, Any?> {
        val bluetoothManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter
        
        return mapOf<String, Any?>(
            "supportsBluetooth" to supportsBluetooth(),
            "supportsBluetoothLE" to supportsBluetoothLE(),
            "isEnabled" to isBluetoothEnabled(),
            "hasPermissions" to hasAllBluetoothPermissions(),
            "deviceName" to (bluetoothAdapter?.name ?: "Unknown"),
            "deviceAddress" to (bluetoothAdapter?.address ?: "Unknown"),
            "androidVersion" to Build.VERSION.SDK_INT,
            "pairedDevicesCount" to getPairedDevices().size
        )
    }
    
    /**
     * Verifica se as permissões foram concedidas após a solicitação
     */
    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == REQUEST_BLUETOOTH_PERMISSIONS) {
            return grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        }
        return false
    }
}
