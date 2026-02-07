/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { setGlobalOptions } from "firebase-functions";
import { onCall, onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as nodemailer from "nodemailer";
import * as admin from "firebase-admin";
import axios from "axios";
import { AccessToken, TrackSource } from "livekit-server-sdk";
import * as dotenv from "dotenv";

// Load environment variables from .env file
dotenv.config();

// Initialize Firebase Admin
admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create reusable transporter object using Gmail SMTP
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "alvin69david@gmail.com", // 🔴 REPLACE WITH YOUR GMAIL ADDRESS
    pass: "yorq gwob ucua cpwt", // 🔴 REPLACE WITH YOUR GMAIL APP PASSWORD
  },
});

// Function to send OTP email
export const sendOTPEmail = onCall(async (request) => {
  try {
    const { email, otpCode } = request.data;

    if (!email || !otpCode) {
      throw new Error("Email and OTP code are required");
    }

    const mailOptions = {
      from: "alvin69david@gmail.com", // 🔴 REPLACE WITH YOUR GMAIL ADDRESS
      to: email,
      subject: "Your Helper App Verification Code",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #FFA10D; text-align: center;">Helper App</h2>
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px; text-align: center;">
            <h3>Your Verification Code</h3>
            <div style="font-size: 32px; font-weight: bold; color: #FFA10D; letter-spacing: 5px; margin: 20px 0;">
              ${otpCode}
            </div>
            <p style="color: #666; margin: 20px 0;">
              This code will expire in 10 minutes for your security.
            </p>
            <p style="color: #666; font-size: 14px;">
              If you didn't request this code, please ignore this email.
            </p>
          </div>
          <p style="text-align: center; color: #999; font-size: 12px; margin-top: 20px;">
            © 2026 Helper App. All rights reserved.
          </p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);

    logger.info(`OTP email sent successfully to ${email}`);
    return { success: true, message: "OTP email sent successfully" };
  } catch (error) {
    logger.error("Error sending OTP email:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    throw new Error(`Failed to send OTP email: ${errorMessage}`);
  }
});

// Function to send Forgot Password OTP email
export const sendForgotPasswordOTPEmail = onCall(async (request) => {
  logger.info("sendForgotPasswordOTPEmail called with request:", request);
  try {
    const { email, otpCode } = request.data;
    logger.info("Extracted email:", email, "otpCode:", otpCode);

    if (!email || !otpCode) {
      logger.info("Missing email or otpCode");
      throw new Error("Email and OTP code are required");
    }

    logger.info("Creating mail options...");
    const mailOptions = {
      from: "alvin69david@gmail.com", // 🔴 REPLACE WITH YOUR GMAIL ADDRESS
      to: email,
      subject: "Your Helper App Password Reset Code",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #FFA10D; text-align: center;">Helper App</h2>
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px; text-align: center;">
            <h3>Password Reset Code</h3>
            <p style="color: #666; margin: 10px 0;">
              We received a request to reset your password. Use the code below to proceed:
            </p>
            <div style="font-size: 32px; font-weight: bold; color: #FFA10D; letter-spacing: 5px; margin: 20px 0;">
              ${otpCode}
            </div>
            <p style="color: #666; margin: 20px 0;">
              This code will expire in 10 minutes for your security.
            </p>
            <p style="color: #666; font-size: 14px;">
              If you didn't request a password reset, please ignore this email.
            </p>
          </div>
          <p style="text-align: center; color: #999; font-size: 12px; margin-top: 20px;">
            © 2026 Helper App. All rights reserved.
          </p>
        </div>
      `,
    };

    logger.info("About to send email to:", email);
    logger.info("Mail options created successfully");

    await transporter.sendMail(mailOptions);

    logger.info("Email sent successfully");
    logger.info(`Forgot Password OTP email sent successfully to ${email}`);
    return {
      success: true,
      message: "Forgot Password OTP email sent successfully",
    };
  } catch (error) {
    console.error("Error in sendForgotPasswordOTPEmail:", error);
    logger.error("Error sending Forgot Password OTP email:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    throw new Error(
      `Failed to send Forgot Password OTP email: ${errorMessage}`,
    );
  }
});

// RELWORX Payment Webhook Handler
export const relworxWebhook = onRequest(
  {
    cors: true,
    maxInstances: 10,
  },
  async (req, res) => {
    try {
      // Only accept POST requests
      if (req.method !== "POST") {
        logger.warn(`Invalid method: ${req.method}`);
        res.status(405).json({ error: "Method not allowed" });
        return;
      }

      const webhookData = req.body;

      // Log the webhook data for debugging
      logger.info("RELWORX Webhook received:", webhookData);

      // Validate webhook payload
      if (
        !webhookData ||
        !webhookData.status ||
        !webhookData.customer_reference
      ) {
        logger.error("Invalid webhook payload:", webhookData);
        res.status(400).json({ error: "Invalid webhook payload" });
        return;
      }

      const {
        status,
        customer_reference,
        internal_reference,
        msisdn,
        amount,
        currency,
        provider,
        charge,
        completed_at,
        message,
      } = webhookData;

      // Extract user ID from customer_reference (format: reg_fee_{timestamp}_{userId})
      const referenceParts = customer_reference.split("_");
      const userId = referenceParts.length >= 3 ? referenceParts[2] : null;

      // Create payment record
      const paymentData = {
        reference: customer_reference,
        userId: userId, // Add userId to payment record
        internalReference: internal_reference,
        phoneNumber: msisdn,
        amount: amount,
        currency: currency,
        provider: provider,
        charge: charge,
        status: status,
        message: message,
        completedAt: completed_at
          ? admin.firestore.Timestamp.fromDate(new Date(completed_at))
          : null,
        webhookReceivedAt: admin.firestore.FieldValue.serverTimestamp(),
        paymentType: "registration_fee",
      };

      const paymentRef = admin
        .firestore()
        .collection("Payments")
        .doc(customer_reference);
      await paymentRef.set(paymentData);

      // If payment is successful and we have userId, update user status
      if (status === "success" && userId) {
        const userRef = admin.firestore().collection("users").doc(userId);
        const userDoc = await userRef.get();

        if (userDoc.exists) {
          await userRef.update({
            registrationFeePaid: true,
            registrationFeePaidAt: admin.firestore.FieldValue.serverTimestamp(),
            registrationFeeAmount: amount,
            registrationFeeReference: customer_reference,
          });

          logger.info(`Updated user ${userId} registration fee status to paid`);
        } else {
          logger.warn(`User document not found for userId: ${userId}`);
        }
      } else if (status === "success" && !userId) {
        // Fallback: Try to find user by phone number
        const usersRef = admin.firestore().collection("users");
        const userQuery = await usersRef
          .where("phoneNumber", "==", msisdn)
          .limit(1)
          .get();

        if (!userQuery.empty) {
          const userDoc = userQuery.docs[0];
          await userDoc.ref.update({
            registrationFeePaid: true,
            registrationFeePaidAt: admin.firestore.FieldValue.serverTimestamp(),
            registrationFeeAmount: amount,
            registrationFeeReference: customer_reference,
          });

          logger.info(
            `Updated user ${userDoc.id} registration fee status to paid (fallback by phone)`,
          );
        } else {
          logger.warn(`User not found for phone number: ${msisdn}`);
        }
      }

      // Acknowledge webhook receipt
      logger.info(
        `Payment webhook processed: ${customer_reference} - ${status}`,
      );
      res.status(200).json({
        success: true,
        message: "Webhook processed successfully",
      });
    } catch (error) {
      logger.error("Error processing RELWORX webhook:", error);
      res.status(500).json({
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  },
);

// Function to check payment status
export const checkPaymentStatus = onCall(async (request) => {
  try {
    const { reference } = request.data;

    if (!reference) {
      throw new Error("Payment reference is required");
    }

    const paymentRef = admin.firestore().collection("Payments").doc(reference);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      return {
        success: false,
        status: "pending",
        message: "Payment not found",
      };
    }

    const paymentData = paymentDoc.data();

    return {
      success: true,
      status: paymentData?.status || "unknown",
      amount: paymentData?.amount,
      currency: paymentData?.currency,
      completedAt: paymentData?.completedAt,
      message: paymentData?.message,
    };
  } catch (error) {
    logger.error("Error checking payment status:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    throw new Error(`Failed to check payment status: ${errorMessage}`);
  }
});

// Function to initiate Airtel payment
export const initiateAirtelPayment = onCall(async (request) => {
  try {
    const { phoneNumber, saveCard, userId } = request.data;

    if (!phoneNumber || !userId) {
      throw new Error("Phone number and user ID are required");
    }

    // Basic validation - Airtel Uganda prefixes: 075, 070, 074(0-2)
    const cleanPhone = phoneNumber.replace(/\s/g, "").replace(/\+/g, "");
    const airtelRegex = RegExp(
      "^(256(75|70|74[0-2])\\d{7}|0(75|70|74[0-2])\\d{7}|(75|70|74[0-2])\\d{7})$",
    );
    if (!airtelRegex.test(cleanPhone)) {
      throw new Error("Please enter a valid Airtel Uganda phone number");
    }

    // Format phone number for RELWORX (ensure international format)
    let formattedPhone = cleanPhone;
    if (formattedPhone.startsWith("0")) {
      formattedPhone = "256" + formattedPhone.substring(1);
    } else if (!formattedPhone.startsWith("256")) {
      formattedPhone = "256" + formattedPhone;
    }

    // RELWORX API configuration
    const apiKey = process.env.RELWORX_API_KEY;
    if (!apiKey) {
      throw new Error("RELWORX_API_KEY not set in environment variables");
    }
    const baseUrl =
      process.env.RELWORX_BASE_URL || "https://payments.relworx.com/api";
    const accountNo = process.env.RELWORX_ACCOUNT_NO || "REL4E261389F7";

    logger.info(
      "API key loaded:",
      !!apiKey,
      "Base URL:",
      baseUrl,
      "Account:",
      accountNo,
    );
    const reference = `reg_fee_${Date.now()}_${userId}`;
    const amount = 25000.0;
    const currency = "UGX";
    const webhookUrl =
      "https://us-central1-helperapp-46849.cloudfunctions.net/relworxWebhook";

    const response = await axios.post(
      `${baseUrl}/mobile-money/request-payment`,
      {
        account_no: accountNo,
        reference: reference,
        msisdn: formattedPhone,
        currency: currency,
        amount: amount,
        description: "Registration Fee Payment",
        webhook_url: webhookUrl,
      },
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          Accept: "application/vnd.relworx.v2",
        },
      },
    );

    const responseData = response.data as {
      success: boolean;
      message?: string;
      [key: string]: any;
    };

    logger.info("RELWORX response:", response.status, responseData);

    if (response.status === 200 && responseData.success === true) {
      // Save phone number if requested
      if (saveCard) {
        const userRef = admin
          .firestore()
          .collection("Saved Payment Methods")
          .doc(userId)
          .collection("Airtel Numbers")
          .doc("latest");

        await userRef.set({
          phoneNumber: phoneNumber,
          savedAt: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
        });
      }

      logger.info(
        `Payment request initiated successfully for user ${userId}: ${reference}`,
      );
      return {
        success: true,
        reference: reference,
        message:
          "Payment request sent successfully! Please complete the payment on your phone.",
      };
    } else {
      logger.error("Payment request failed:", responseData);
      throw new Error(
        `Payment request failed: ${responseData.message || "Unknown error"}`,
      );
    }
  } catch (error) {
    logger.error("Error initiating Airtel payment:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    throw new Error(`Failed to initiate payment: ${errorMessage}`);
  }
});

// Function to reset password after OTP verification
export const resetPasswordAfterOTP = onCall(async (request) => {
  try {
    const { email, newPassword } = request.data;

    if (!email || !newPassword) {
      throw new Error("Email and new password are required");
    }

    if (newPassword.length < 6) {
      throw new Error("Password must be at least 6 characters");
    }

    // Note: In a production app, you would use Firebase Admin SDK to update the password
    // Since we're using client-side Firebase, we'll send a confirmation email
    // In production, implement server-side password update with Admin SDK

    await transporter.sendMail({
      from: "alvin69david@gmail.com",
      to: email,
      subject: "Your Helper App Password Has Been Reset",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #FFA10D; text-align: center;">Helper App</h2>
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px; text-align: center;">
            <h3>Password Reset Successful</h3>
            <p style="color: #666; margin: 10px 0;">
              Your password has been successfully reset. You can now sign in with your new password.
            </p>
            <p style="color: #666; font-size: 14px;">
              If you didn't request this change, please contact support immediately.
            </p>
          </div>
          <p style="text-align: center; color: #999; font-size: 12px; margin-top: 20px;">
            © 2026 Helper App. All rights reserved.
          </p>
        </div>
      `,
    });

    logger.info(`Password reset confirmation sent to ${email}`);
    return { success: true, message: "Password reset successful" };
  } catch (error) {
    logger.error("Error resetting password:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    throw new Error(`Failed to reset password: ${errorMessage}`);
  }
});

// Function to send call notification
export const sendCallNotification = onDocumentCreated(
  "calls/{callId}",
  async (event) => {
    logger.info("=== CLOUD FUNCTION sendCallNotification TRIGGERED ===");
    logger.info("Call ID:", event.params.callId);

    const call = event.data?.data();
    if (!call) {
      logger.info("ERROR: Call data is null");
      return;
    }

    logger.info("Call data:", call);

    const receiverId = call.receiverId;
    if (!receiverId) {
      logger.info("ERROR: Receiver ID is null");
      return;
    }

    logger.info("Receiver ID:", receiverId);

    try {
      logger.info("Fetching receiver document from Firestore...");
      const receiverDoc = await admin
        .firestore()
        .collection("users")
        .doc(receiverId)
        .get();

      if (!receiverDoc.exists) {
        logger.info("ERROR: Receiver document does not exist");
        return;
      }

      const fcmToken = receiverDoc.data()?.fcmToken;
      if (!fcmToken) {
        logger.info("ERROR: No FCM token found for user", receiverId);
        return;
      }

      logger.info("FCM token found for receiver:", receiverId);
      logger.info("FCM token preview:", fcmToken.substring(0, 50) + "...");

      const callerName = call.callerName || "Unknown Caller";
      logger.info("Caller name:", callerName);

      logger.info("Sending FCM notification...");

      await admin.messaging().send({
        token: fcmToken,
        data: {
          type: "call",
          callId: event.params.callId,
          callerName: callerName,
        },
        notification: {
          title: "Incoming Call",
          body: `${callerName} is calling you`,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "calls",
            priority: "high",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      logger.info("SUCCESS: Call notification sent to", receiverId);
    } catch (error) {
      logger.info("ERROR sending call notification:", error);
    }
  },
);

// Function to send review notification
export const sendReviewNotification = onDocumentCreated(
  "Reviews/{reviewId}",
  async (event) => {
    logger.info("=== CLOUD FUNCTION sendReviewNotification TRIGGERED ===");
    logger.info("Review ID:", event.params.reviewId);

    const review = event.data?.data();
    if (!review) {
      logger.info("ERROR: Review data is null");
      return;
    }

    logger.info("Review data:", review);

    const providerId = review.providerId;
    if (!providerId) {
      logger.info("ERROR: Provider ID is null");
      return;
    }

    logger.info("Provider ID:", providerId);

    try {
      logger.info("Fetching provider document from Firestore...");
      const providerDoc = await admin
        .firestore()
        .collection("users")
        .doc(providerId)
        .get();

      if (!providerDoc.exists) {
        logger.info("ERROR: Provider document does not exist");
        return;
      }

      const fcmToken = providerDoc.data()?.fcmToken;
      if (!fcmToken) {
        logger.info("ERROR: No FCM token found for user", providerId);
        return;
      }

      logger.info("FCM token found for provider:", providerId);
      logger.info("FCM token preview:", fcmToken.substring(0, 50) + "...");

      const reviewerName = review.reviewerName || "A customer";
      const rating = review.rating || 0;
      const reviewText = review.reviewText || "";

      logger.info("Reviewer name:", reviewerName);
      logger.info("Rating:", rating);
      logger.info("Review text:", reviewText);

      logger.info("Sending FCM notification...");

      await admin.messaging().send({
        token: fcmToken,
        data: {
          type: "review",
          reviewId: event.params.reviewId,
          reviewerName: reviewerName,
          rating: rating.toString(),
          reviewText: reviewText,
        },
        notification: {
          title: "New Review Received",
          body: `${reviewerName} gave you ${rating} stars: "${reviewText.length > 50 ? reviewText.substring(0, 50) + "..." : reviewText}"`,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "reviews",
            priority: "high",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      // Create notification document for the worker
      logger.info(
        "Creating notification document in workerNotifications collection...",
      );
      await admin
        .firestore()
        .collection("workerNotifications")
        .add({
          workerId: providerId,
          type: "review",
          title: "New Review Received",
          message: `${reviewerName} gave you ${rating} stars`,
          reviewText: reviewText,
          reviewerName: reviewerName,
          rating: rating,
          reviewId: event.params.reviewId,
          read: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

      logger.info("Notification document created successfully");

      logger.info("SUCCESS: Review notification sent to", providerId);
    } catch (error) {
      logger.info("ERROR sending review notification:", error);
    }
  },
);

// Test function to verify Cloud Functions are working
// Function to test call notification (callable function)
export const testCallNotification = onCall(async (request) => {
  logger.info("=== TEST CALL NOTIFICATION FUNCTION CALLED ===");
  logger.info("Request data:", request.data);

  return {
    success: true,
    message: "Cloud Function is working! Check Firebase Functions logs.",
    timestamp: new Date().toISOString(),
  };
});

// Function to generate LiveKit token for voice calls
export const generateLiveKitToken = onCall(async (request) => {
  try {
    const { roomName, identity } = request.data;

    if (!roomName || !identity) {
      throw new Error("Missing required parameters: roomName and identity");
    }

    const token = new AccessToken(
      process.env.LIVEKIT_API_KEY!,
      process.env.LIVEKIT_API_SECRET!,
    );

    token.identity = identity;
    token.name = identity; // Optional: set display name
    token.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishSources: [TrackSource.MICROPHONE], // Voice calls only
    });

    const jwt = token.toJwt();

    return { token: jwt };
  } catch (error) {
    logger.error("Error generating LiveKit token:", error);
    throw new Error("Failed to generate token");
  }
});

// Function to validate an Airtel Uganda mobile number via Relworx
export const validateMobileNumber = onRequest(
  {
    cors: true,
    maxInstances: 10,
  },
  async (req, res) => {
    logger.info("DEBUG: Validation request received", { body: req.body });

    try {
      const { msisdn, userId } = req.body;

      if (!msisdn || !userId) {
        res.status(400).json({ success: false, message: "Missing msisdn or userId" });
        return;
      }

      // 1. Normalize the phone number to +256XXXXXXXXX format
      let normalizedMsisdn = msisdn.replace(/\D/g, ""); // remove non-digits
      if (normalizedMsisdn.startsWith("0")) {
        normalizedMsisdn = "+256" + normalizedMsisdn.slice(1);
      } else if (normalizedMsisdn.startsWith("256")) {
        normalizedMsisdn = "+256" + normalizedMsisdn.slice(3);
      } else if (!normalizedMsisdn.startsWith("+256")) {
        normalizedMsisdn = "+256" + normalizedMsisdn;
      }

      // 2. Local Regex for Airtel Uganda prefixes (70, 74, 75)
      const airtelRegex = /^\+256(70|74|75)\d{7}$/;
      if (!airtelRegex.test(normalizedMsisdn)) {
        logger.info("DEBUG: Failed Airtel prefix check", { msisdn: normalizedMsisdn });
        res.json({ success: false, message: "Please enter a valid Airtel Uganda number" });
        return;
      }

      // 3. Verify the user exists in your "Sign Up" collection
      const userDoc = await admin.firestore().collection("Sign Up").doc(userId).get();
      if (!userDoc.exists) {
        logger.warn("DEBUG: User not found", { userId });
        res.status(403).json({ success: false, message: "User not registered" });
        return;
      }

      // 4. Call Relworx API
      const apiUrl = `${process.env.RELWORX_BASE_URL}/mobile-money/validate`;
      const apiKey = process.env.RELWORX_API_KEY;

      const response = await axios.post(
        apiUrl,
        { msisdn: normalizedMsisdn },
        {
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/vnd.relworx.v2",
            "Authorization": `Bearer ${apiKey}`, // ✅ FIXED: Must be Bearer
          },
        }
      );

      logger.info("DEBUG: Relworx Response", response.data);

      const responseData = response.data as { customer_name?: string };

      if (responseData.customer_name) {
        res.json({
          success: true,
          customer_name: responseData.customer_name,
        });
      } else {
        res.json({ success: false, message: "Mobile number is invalid or not registered" });
      }
    } catch (error: any) {
      logger.error("DEBUG: Main Error", {
        msg: error.message,
        relworxMsg: error.response?.data
      });

      const errorMessage = error.response?.data?.message || "Validation service currently unavailable";
      res.status(200).json({ success: false, message: errorMessage });
    }
  }
);


// Function to request payment
export const requestPayment = onCall(
  {
    invoker: "public", // Allow unauthenticated calls
  },
  async (request) => {
    try {
      const {
        account_no,
        reference,
        msisdn,
        currency,
        amount,
        description,
        webhook_url,
        saveCard,
        userId,
        originalPhoneNumber,
      } = request.data;

      if (!userId) {
        throw new Error("userId is required");
      }

      // Check if user exists in Sign Up collection
      const userDoc = await admin
        .firestore()
        .collection("Sign Up")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        throw new Error("User not found in Sign Up collection");
      }

      if (
        !account_no ||
        !reference ||
        !msisdn ||
        !currency ||
        !amount ||
        !description
      ) {
        throw new Error("All payment request fields are required");
      }

      const requestData: any = {
        account_no,
        reference,
        msisdn,
        currency,
        amount,
        description,
      };

      // Add webhook_url if provided
      if (webhook_url) {
        requestData.webhook_url = webhook_url;
      }

      const response = await axios.post(
        `${process.env.RELWORX_BASE_URL}/mobile-money/request-payment`,
        requestData,
        {
          headers: {
            "Content-Type": "application/json",
            Accept: "application/vnd.relworx.v2",
            Authorization: `Bearer ${process.env.RELWORX_API_KEY}`,
          },
        },
      );

      const responseData = response.data as {
        success: boolean;
        message?: string;
        [key: string]: any;
      };

      // If this is for Airtel payment with saveCard option, save the phone number
      if (saveCard && userId && originalPhoneNumber) {
        const userRef = admin
          .firestore()
          .collection("Saved Payment Methods")
          .doc(userId)
          .collection("Airtel Numbers")
          .doc("latest");

        await userRef.set({
          phoneNumber: originalPhoneNumber,
          savedAt: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
        });

        logger.info(`Phone number saved for user ${userId}`);
      }

      logger.info(
        `Payment request successful for ${msisdn}, amount: ${amount} ${currency}`,
      );
      return responseData;
    } catch (error) {
      logger.error("Error requesting payment:", error);
      const errorMessage =
        error instanceof Error ? error.message : "Unknown error";
      throw new Error(`Failed to request payment: ${errorMessage}`);
    }
  },
);

// Function to send review notification to worker (manual)
export const sendReviewNotificationManually = onCall(async (request) => {
  try {
    const { workerId, employerId, rating, reviewText } = request.data;

    if (!workerId || !employerId || rating == null) {
      throw new Error("workerId, employerId, and rating are required");
    }

    // Get worker's FCM token
    const workerDoc = await admin
      .firestore()
      .collection("users")
      .doc(workerId)
      .get();

    if (!workerDoc.exists) {
      throw new Error("Worker not found");
    }

    const workerData = workerDoc.data();
    const fcmToken = workerData?.fcmToken;

    if (!fcmToken) {
      logger.warn(`No FCM token found for worker ${workerId}`);
      return { success: false, message: "Worker has no FCM token" };
    }

    // Get employer name
    const employerDoc = await admin
      .firestore()
      .collection("users")
      .doc(employerId)
      .get();

    const employerName = employerDoc.exists
      ? employerDoc.data()?.name || "Employer"
      : "Employer";

    // Prepare notification message
    const title = "New Review Received";
    const body = `${employerName} gave you ${rating} star${rating !== 1 ? "s" : ""}${reviewText ? ": " + reviewText : ""}`;

    // Send FCM notification
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "review",
        workerId: workerId,
        employerId: employerId,
        rating: rating.toString(),
        reviewText: reviewText || "",
      },
    };

    const response = await admin.messaging().send(message);

    logger.info(`Review notification sent to worker ${workerId}: ${response}`);

    return { success: true, message: "Notification sent successfully" };
  } catch (error) {
    logger.error("Error sending review notification:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    throw new Error(`Failed to send review notification: ${errorMessage}`);
  }
});

// Webhook handler for payment status updates
export const paymentWebhook = onRequest(async (req, res) => {
  try {
    // Only accept POST requests
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    // Parse the webhook payload
    const webhookData = req.body;

    // Validate required fields
    const {
      status,
      message,
      customer_reference,
      internal_reference,
      msisdn,
      amount,
      currency,
      provider,
      charge,
      completed_at,
    } = webhookData;

    if (!status || !customer_reference || !internal_reference) {
      logger.error(
        "Invalid webhook payload: missing required fields",
        webhookData,
      );
      res.status(400).send("Invalid payload");
      return;
    }

    logger.info(
      `Payment webhook received: ${status} for ${customer_reference}`,
    );

    // Store the payment status in Firestore
    const paymentRef = admin
      .firestore()
      .collection("payments")
      .doc(customer_reference);
    await paymentRef.set(
      {
        status,
        message,
        customer_reference,
        internal_reference,
        msisdn,
        amount,
        currency,
        provider,
        charge,
        completed_at: completed_at ? new Date(completed_at) : null,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // If payment is successful, you might want to trigger additional actions
    // For example, update user balance, send notifications, etc.
    if (status === "success") {
      // TODO: Implement success handling logic
      logger.info(
        `Payment successful: ${customer_reference} - ${amount} ${currency}`,
      );
    } else if (status === "failed") {
      // TODO: Implement failure handling logic
      logger.warn(`Payment failed: ${customer_reference} - ${message}`);
    }

    // Acknowledge the webhook with 200 OK
    res.status(200).send("OK");
  } catch (error) {
    logger.error("Error processing payment webhook:", error);
    // Still return 200 to acknowledge receipt, but log the error
    res.status(200).send("OK");
  }
});
