package play.store.vibelytics

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability

class MainActivity : FlutterActivity() {
    private val CHANNEL = "vibelytics/google_auth"
    private val RC_SIGN_IN = 9001
    private var pendingResult: MethodChannel.Result? = null
    private var pendingServerClientId: String? = null
    private var pendingAndroidClientId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "signInWithGoogle" -> {
                    if (pendingResult != null) {
                        result.error(
                            "GOOGLE_SIGN_IN_IN_PROGRESS",
                            "A Google sign-in flow is already running",
                            googleErrorDetails(12502)
                        )
                        return@setMethodCallHandler
                    }

                    val serverClientId = call.argument<String>("serverClientId")
                    if (serverClientId == null) {
                        result.error("MISSING_ARG", "serverClientId is required", null)
                        return@setMethodCallHandler
                    }

                    val playServicesStatus =
                        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(this)
                    if (playServicesStatus != ConnectionResult.SUCCESS) {
                        result.error(
                            "GOOGLE_PLAY_SERVICES_UNAVAILABLE",
                            "Google Play Services unavailable: $playServicesStatus",
                            googleErrorDetails(
                                playServicesStatus,
                                serverClientId,
                                call.argument<String>("androidClientId")
                            )
                        )
                        return@setMethodCallHandler
                    }

                    pendingResult = result
                    pendingServerClientId = serverClientId
                    pendingAndroidClientId = call.argument<String>("androidClientId")
                    startGoogleSignIn(serverClientId)
                }
                "signOut" -> {
                    val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN).build()
                    GoogleSignIn.getClient(this, gso).signOut()
                        .addOnCompleteListener { result.success(null) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startGoogleSignIn(serverClientId: String) {
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(serverClientId)
            .requestEmail()
            .requestProfile()
            .build()

        val client = GoogleSignIn.getClient(this, gso)
        // Sign out first to force account picker
        client.signOut().addOnCompleteListener {
            try {
                startActivityForResult(client.signInIntent, RC_SIGN_IN)
            } catch (e: Exception) {
                val result = pendingResult
                pendingResult = null
                pendingServerClientId = null
                pendingAndroidClientId = null
                result?.error("SIGN_IN_FAILED", "Google Sign-In failed to start: ${e.message}", null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == RC_SIGN_IN) {
            val result = pendingResult
            pendingResult = null

            if (result == null) return

            try {
                val task = GoogleSignIn.getSignedInAccountFromIntent(data)
                val account = task.getResult(ApiException::class.java)

                val response = HashMap<String, String?>()
                response["idToken"] = account.idToken
                response["email"] = account.email
                response["displayName"] = account.displayName
                response["id"] = account.id
                response["photoUrl"] = account.photoUrl?.toString()

                result.success(response)
            } catch (e: ApiException) {
                val statusCode = e.statusCode
                val errorCode = googleErrorCode(statusCode)

                if (errorCode == "CANCELLED") {
                    // User cancelled
                    result.error("CANCELLED", "Sign-in cancelled by user", null)
                } else {
                    result.error(
                        errorCode,
                        "Google Sign-In failed: $statusCode (${googleStatusName(statusCode)}) - ${e.message}",
                        googleErrorDetails(statusCode, pendingServerClientId, pendingAndroidClientId)
                    )
                }
            } finally {
                pendingServerClientId = null
                pendingAndroidClientId = null
            }
        }
    }

    private fun googleErrorCode(statusCode: Int): String {
        return when (statusCode) {
            12501 -> "CANCELLED"
            10 -> "GOOGLE_DEVELOPER_ERROR"
            7 -> "GOOGLE_NETWORK_ERROR"
            12502 -> "GOOGLE_SIGN_IN_IN_PROGRESS"
            else -> "SIGN_IN_FAILED"
        }
    }

    private fun googleStatusName(statusCode: Int): String {
        return when (statusCode) {
            4 -> "SIGN_IN_REQUIRED"
            7 -> "NETWORK_ERROR"
            8 -> "INTERNAL_ERROR"
            10 -> "DEVELOPER_ERROR"
            12500 -> "SIGN_IN_FAILED"
            12501 -> "SIGN_IN_CANCELLED"
            12502 -> "SIGN_IN_CURRENTLY_IN_PROGRESS"
            else -> "UNKNOWN"
        }
    }

    private fun googleErrorDetails(
        statusCode: Int,
        serverClientId: String? = pendingServerClientId,
        androidClientId: String? = pendingAndroidClientId
    ): HashMap<String, Any?> {
        val details = HashMap<String, Any?>()
        details["statusCode"] = statusCode
        details["statusName"] = googleStatusName(statusCode)
        details["packageName"] = packageName
        details["serverClientId"] = serverClientId
        details["androidClientId"] = androidClientId
        return details
    }
}
