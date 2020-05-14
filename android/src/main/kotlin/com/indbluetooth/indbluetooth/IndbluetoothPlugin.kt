package com.indbluetooth.indbluetooth

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.onecoder.devicelib.FitBleKit
import com.onecoder.devicelib.armband.api.ArmBandManager
import com.onecoder.devicelib.armband.api.entity.StepFrequencyEntity
import com.onecoder.devicelib.armband.api.interfaces.RealTimeDataListener
import com.onecoder.devicelib.base.control.entity.BleDevice
import com.onecoder.devicelib.base.control.entity.BluetoothBean
import com.onecoder.devicelib.base.control.interfaces.BleScanCallBack
import com.onecoder.devicelib.base.control.interfaces.CheckSystemBleCallback
import com.onecoder.devicelib.base.control.interfaces.DeviceStateChangeCallback
import com.onecoder.devicelib.base.control.manage.BleScanner
import com.onecoder.devicelib.base.entity.BaseDevice
import com.onecoder.devicelib.base.entity.DeviceType
import com.onecoder.devicelib.base.protocol.entity.RTHeartRate
import com.onecoder.devicelib.utils.BluetoothUtils
import com.yanzhenjie.permission.AndPermission
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject

class IndbluetoothPlugin: MethodCallHandler {

  val START_SCAN = "startScan"
  val STOP_SCAN = "stopScan"
  val START_READ = "startRead"
  val STOP_READ = "stopRead"

  val deviceListChannelName = "deviceListChannelName"
  val heartrateChannelName = "heartrateChannelName"

  val permissionArray = arrayOf("android.permission.BLUETOOTH", "android.permission.BLUETOOTH_ADMIN", "android.permission.ACCESS_COARSE_LOCATION", "android.permission.ACCESS_FINE_LOCATION")

  var activity: Activity? = null

  //蓝牙列表
  var bluetoothBeans = mutableListOf<BluetoothBean>()

  var deviceListSink: EventChannel.EventSink? = null
  var deviceListChannel: EventChannel? = null
  var heartrateSink: EventChannel.EventSink? = null
  var heartrateChannel: EventChannel? = null

  companion object {
    val TAG = "IndbluetoothPlugin"
    val pluginName = "IndbluetoothPluginName"
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), pluginName)
      channel.setMethodCallHandler(IndbluetoothPlugin(registrar))
    }
  }

  constructor(registrar: Registrar) {
    activity = registrar.activity()
    FitBleKit.getInstance().initSDK(registrar.activity().applicationContext)

    deviceListChannel = EventChannel(registrar.messenger(), deviceListChannelName)
    deviceListChannel?.setStreamHandler(object: EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        deviceListSink = events
      }

      override fun onCancel(arguments: Any?) {
        deviceListSink = null
      }
    })

    heartrateChannel = EventChannel(registrar.messenger(), heartrateChannelName)
    heartrateChannel?.setStreamHandler(object: EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        heartrateSink = events
      }

      override fun onCancel(arguments: Any?) {
        heartrateSink = null
      }
    })

    registrar.addActivityResultListener(object: PluginRegistry.ActivityResultListener {
      override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == CMD_REQUEST_ENABLE_BLE) {
          isRequestingSwitchOnBle = false
        }
        return true
      }

    })
  }

  /***************蓝牙******************/
  val CMD_REQUEST_ENABLE_BLE = 1
  var isRequestingSwitchOnBle = false

  var scanner: BleScanner? = null
  var armBandManager: ArmBandManager? = null
  var baseDevice: BaseDevice? = null

  var systemCallback = object: CheckSystemBleCallback {
    override fun onBleSwitchedBySystem(switchOn: Boolean) {
      isRequestingSwitchOnBle = false
      Log.i(TAG, "onBleSwitchedBySystem switchOn:$switchOn")
    }

    override fun onRequestSwitchOnBle() {
      if (!isRequestingSwitchOnBle) {
        isRequestingSwitchOnBle = true
        BluetoothUtils.checkEnabledBluetooth(activity, CMD_REQUEST_ENABLE_BLE)
      }
    }
  }

  var scanCallback = object: BleScanCallBack {
    override fun unFindDevice() {
    }

    override fun findDevice(bean: BluetoothBean?) {
      bean?.let {
        if (bluetoothBeanNotExist(it)) {
          bluetoothBeans.add(it)
          val jsonObj = JSONObject()
          jsonObj.put("name", it.bleDevice.name)
          jsonObj.put("address", it.bleDevice.address)
          deviceListSink?.success(jsonObj.toString())
        }
      }
    }
  }

  fun bluetoothBeanNotExist(bean: BluetoothBean): Boolean {
    return bluetoothBeans.none { item ->
      item.bleDevice.address == bean.bleDevice.address
    }
  }

  fun getBleScanner(): BleScanner? {
    if (scanner != null) {
      return scanner
    }
    scanner = BleScanner()
    //添加需要扫描出来的手环，不添加默认扫描所有的设备
    scanner?.addNameFilter(DeviceType.ArmBand, arrayOf("HW", "BD"))
    return scanner
  }

  fun getManager(): ArmBandManager? {
    if (armBandManager != null) {
      return armBandManager
    }
    armBandManager = ArmBandManager.getInstance()
    return armBandManager
  }

  /**
   * 实时数据回调接口
   */
  private val realTimeDataListener = object : RealTimeDataListener {
    /**
     * 获取到电池电量
     *
     * @param batteryLevel 电池电量。取值范围:0-100
     */
    override fun onGotBatteryLevel(batteryLevel: Int) {
      Log.i(TAG, "onRealTimeBattery value:$batteryLevel")
    }

    override fun onRealTimeHeartRateData(value: RTHeartRate) {
      Log.i(TAG, "onRealTimeHeartRateData value:$value")
      if (armBandManager != null) {
        armBandManager?.getBatteryLevel()
      }
      heartrateSink?.success(value.heartRate)
    }

    override fun onRealTimeStepFrequencyData(value: StepFrequencyEntity) {
      Log.i(TAG, "onRealTimeStepFrequencyData value:$value")
    }
  }

  /**
   * 手环的连接状态回调
   */
  private val stateChangeCallback = object : DeviceStateChangeCallback {
    /**
     * 手环的连接状态变化回调
     * @param mac ：mac地址
     * @param status ：状态值
     */
    override fun onStateChange(mac: String, status: Int) {
      updateConnectStatus(status)
    }

    /**
     * 手环可以下发数据的回调，新协议称可以在此时设置用户信息、闹钟、健康开关等
     * @param mac
     * @param isNeedSetParam
     */
    override fun onEnableWriteToDevice(mac: String, isNeedSetParam: Boolean) {
      Log.i(TAG, "onEnableWriteToDevice mac:$mac isNeedSetParam:$isNeedSetParam")
    }
  }

  fun updateConnectStatus(status: Int) {
//    var connectSate = R.string.un_stpes_walk
    when (status) {
      BleDevice.STATE_DISCONNECTED  //断开连接
      -> {
//        initBeforeConnectUI()
      }
      BleDevice.STATE_CONNECTING  //正在连接
      -> {
//        card_state.setContentColor(R.color.btn_red)
//        connectSate = R.string.device_connecting
      }
      BleDevice.STATE_CONNECTED  //已连接
      -> {
//        card_state.setContentColor(R.color.btn_green)
//        connectSate = R.string.stpes_walk
      }
      BleDevice.STATE_SERVICES_DISCOVERED  //发现服务
      -> {
//        card_state.setContentColor(R.color.btn_green)
//        connectSate = R.string.stpes_walk
      }
      BleDevice.STATE_SERVICES_OPENCHANNELSUCCESS
      -> {
//        card_state.setContentColor(R.color.btn_green)
//        connectSate = R.string.stpes_walk
      }
    }
//    card_state.setContent(getString(connectSate))
  }

  /**
   * @param isScan true 扫描  false ：停止扫描
   */
  fun scanEnableDevice(isScan: Boolean) {
    if (isScan) {
      bluetoothBeans.clear()
      scanner?.startScan(scanCallback)
    } else {
      scanner?.stopScan()
    }
  }

  //连接设备
  fun connectDev() {
    scanEnableDevice(false)
    armBandManager?.connectDevice(baseDevice)
  }

  //连接设备前与上次连接设备断开
  fun disconThenConnectDevice() {
    disconnectDevice()
    connectDev()
  }

  fun disconnectDevice() {
    scanEnableDevice(false)
    armBandManager?.disconnect(false)
    armBandManager?.closeDevice()
    armBandManager?.refreshDeviceCache()
  }
  /***************蓝牙******************/

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == START_SCAN) {
      AndPermission.with(activity)
              .runtime()
              .permission(permissionArray)
              .onGranted {
                scanner = getBleScanner()
                armBandManager = getManager()

                scanner?.registerCheckSystemBleCallback(systemCallback)
                armBandManager?.registerCheckSystemBleCallback(systemCallback)

                armBandManager?.registerStateChangeCallback(stateChangeCallback)
                armBandManager?.registerRealTimeDataListner(realTimeDataListener)

                scanEnableDevice(true)
                result.success(START_SCAN)
              }
              .onDenied{
              }
              .start()

    } else if (call.method == STOP_SCAN) {
      scanEnableDevice(false)
      scanner?.unregisterCheckSystemBleCallback(systemCallback)
      armBandManager?.unregisterCheckSystemBleCallback(systemCallback)

      armBandManager?.unregistStateChangeCallback(stateChangeCallback)
      armBandManager?.unregistRealTimeDataListner(realTimeDataListener)
      result.success(STOP_SCAN)
    } else if (call.method == START_READ) {
      AndPermission.with(activity)
              .runtime()
              .permission(permissionArray)
              .onGranted {
                val address: String = call.arguments()
                val currentBean = bluetoothBeans.find {
                  it.bleDevice.address == address
                }
                currentBean?.let {
                  scanner = getBleScanner()
                  armBandManager = getManager()

                  scanner?.registerCheckSystemBleCallback(systemCallback)
                  armBandManager?.registerCheckSystemBleCallback(systemCallback)

                  armBandManager?.registerStateChangeCallback(stateChangeCallback)
                  armBandManager?.registerRealTimeDataListner(realTimeDataListener)

                  baseDevice = BaseDevice()
                  baseDevice?.deviceType = DeviceType.ArmBand
                  baseDevice?.macAddress = it.bleDevice.address
                  baseDevice?.name = it.bleDevice.name
                  disconThenConnectDevice()
                  result.success(START_READ)
                }
              }
              .onDenied{
              }
              .start()

    } else if (call.method == STOP_READ) {
      scanEnableDevice(false)
      scanner?.unregisterCheckSystemBleCallback(systemCallback)
      armBandManager?.unregisterCheckSystemBleCallback(systemCallback)

      armBandManager?.unregistStateChangeCallback(stateChangeCallback)
      armBandManager?.unregistRealTimeDataListner(realTimeDataListener)
      disconnectDevice()
      result.success(STOP_READ)
    }
  }


}
