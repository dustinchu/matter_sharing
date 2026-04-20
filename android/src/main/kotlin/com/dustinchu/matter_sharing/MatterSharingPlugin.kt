package com.dustinchu.matter_sharing

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

import android.util.Log
import com.google.android.gms.home.matter.Matter
import com.google.android.gms.home.matter.commissioning.CommissioningRequest
import com.google.android.gms.home.matter.commissioning.CommissioningWindow
import com.google.android.gms.home.matter.commissioning.ShareDeviceRequest
import com.google.android.gms.home.matter.common.DeviceDescriptor
import com.google.android.gms.home.matter.common.Discriminator

class MatterSharingPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var activityBinding: ActivityPluginBinding? = null

    companion object {
        private const val CHANNEL = "matter_sharing"
        private const val REQUEST_CODE_MATTER = 1001
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "shareToGoogleHome" -> {
                val onboardingPayload = call.argument<String>("onboardingPayload") ?: ""
                val discriminator = call.argument<Int>("discriminator")
                val passcode = call.argument<Int>("passcode")?.toLong()
                val durationSeconds = call.argument<Int>("durationSeconds")
                val vendorId = call.argument<Int>("vendorId")
                val productId = call.argument<Int>("productId")
                val deviceType = call.argument<Int>("deviceType")
                shareToGoogleHome(onboardingPayload, discriminator, passcode, durationSeconds, vendorId, productId, deviceType, result)
            }
            "shareToAppleHome" -> {
                // Apple Home is iOS only
                result.error("UNSUPPORTED", "shareToAppleHome is only available on iOS", null)
            }
            "configureGoogleHome" -> {
                // Android config is done via gradle/manifest, not at runtime
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun shareToGoogleHome(
        onboardingPayload: String,
        discriminator: Int?,
        passcode: Long?,
        durationSeconds: Int?,
        vendorId: Int?,
        productId: Int?,
        deviceType: Int?,
        result: Result
    ) {
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
            return
        }
        pendingResult = result

        Log.d("MatterSharing", "shareToGoogleHome called: onboardingPayload=$onboardingPayload, discriminator=$discriminator, passcode=$passcode, durationSeconds=$durationSeconds")

        if (discriminator != null && passcode != null) {
            Log.d("MatterSharing", "Branch: shareDevice (discriminator+passcode present)")
            // Device already in our fabric - use shareDevice for multi-fabric
            val commissioningWindow = CommissioningWindow.builder()
                .setDiscriminator(Discriminator.forLongValue(discriminator))
                .setPasscode(passcode)
                .setWindowOpenMillis(System.currentTimeMillis())
                .setDurationSeconds((durationSeconds ?: 900).toLong())
                .build()
            val deviceDescriptor = DeviceDescriptor.builder()
                .setVendorId(vendorId ?: 0xFFF1)
                .setProductId(productId ?: 0x8000)
                .setDeviceType(deviceType ?: 0x0300)
                .build()
            val request = ShareDeviceRequest.builder()
                .setCommissioningWindow(commissioningWindow)
                .setDeviceDescriptor(deviceDescriptor)
                .setDeviceName("Matter Device")
                .build()
            Matter.getCommissioningClient(act)
                .shareDevice(request)
                .addOnSuccessListener { intentSender ->
                    Log.d("MatterSharing", "shareDevice intentSender received, launching UI")
                    act.startIntentSenderForResult(intentSender, REQUEST_CODE_MATTER, null, 0, 0, 0)
                }
                .addOnFailureListener { e ->
                    Log.e("MatterSharing", "shareDevice failed: ${e.message}", e)
                    pendingResult?.error("GOOGLE_HOME_ERROR", e.message, null)
                    pendingResult = null
                }
        } else {
            Log.d("MatterSharing", "Branch: commissionDevice (no discriminator/passcode)")
            // New device - use commissionDevice
            val request = CommissioningRequest.builder()
                .setOnboardingPayload(onboardingPayload)
                .build()
            Matter.getCommissioningClient(act)
                .commissionDevice(request)
                .addOnSuccessListener { intentSender ->
                    Log.d("MatterSharing", "commissionDevice intentSender received, launching UI")
                    act.startIntentSenderForResult(intentSender, REQUEST_CODE_MATTER, null, 0, 0, 0)
                }
                .addOnFailureListener { e ->
                    Log.e("MatterSharing", "commissionDevice failed: ${e.message}", e)
                    pendingResult?.error("GOOGLE_HOME_ERROR", e.message, null)
                    pendingResult = null
                }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_MATTER) {
            Log.d("MatterSharing", "onActivityResult: resultCode=$resultCode, data=$data")
            if (resultCode == Activity.RESULT_OK) {
                Log.d("MatterSharing", "Commissioning result: SUCCESS")
                pendingResult?.success(null)
            } else {
                Log.w("MatterSharing", "Commissioning result: CANCELLED or FAILED (resultCode=$resultCode)")
                pendingResult?.error("CANCELLED", "User cancelled Google Home commissioning", null)
            }
            pendingResult = null
            return true
        }
        return false
    }
}
