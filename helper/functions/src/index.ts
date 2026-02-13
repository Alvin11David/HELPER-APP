/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { setGlobalOptions } from "firebase-functions";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
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

// Function to send OTP push notification
export const sendOTPPhone = onCall(async (request) => {
  try {
    const { phoneNumber, otpCode, fcmToken } = request.data;

    if (!phoneNumber || !otpCode || !fcmToken) {
      throw new Error("Phone number, OTP code, and FCM token are required");
    }

    // Send push notification using Firebase Admin
    const message = {
      token: fcmToken,
      notification: {
        title: "Helper App Verification",
        body: `Your verification code is: ${otpCode}`,
      },
      data: {
        type: "otp",
        otpCode: otpCode,
        phoneNumber: phoneNumber,
      },
    };

    await admin.messaging().send(message);

    logger.info(`OTP push notification sent successfully to ${phoneNumber}`);
    return {
      success: true,
      message: "OTP push notification sent successfully",
    };
  } catch (error) {
    logger.error("Error sending OTP push notification:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    throw new Error(`Failed to send OTP push notification: ${errorMessage}`);
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
      };

      const paymentRef = admin
        .firestore()
        .collection("Payment Data")
        .doc(customer_reference);
      await paymentRef.set(paymentData);

      // If payment is successful and we have userId, update user status
      if (status.toLowerCase() === "success" && userId) {
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
      } else if (status.toLowerCase() === "success" && !userId) {
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
      logger.info("Resolving provider user for notification...");
      const db = admin.firestore();
      let targetUid = providerId as string;

      const serviceProviderDoc = await db
        .collection("serviceProviders")
        .doc(providerId)
        .get();
      if (serviceProviderDoc.exists) {
        const workerUid = (
          serviceProviderDoc.data()?.workerUid ?? ""
        ).toString();
        if (workerUid) {
          targetUid = workerUid;
        }
      }

      let fcmToken: string | undefined;
      const signUpDoc = await db.collection("Sign Up").doc(targetUid).get();
      if (signUpDoc.exists) {
        fcmToken = signUpDoc.data()?.fcmToken as string | undefined;
      }

      if (!fcmToken) {
        const usersDoc = await db.collection("users").doc(targetUid).get();
        fcmToken = usersDoc.data()?.fcmToken as string | undefined;
      }

      if (!fcmToken) {
        logger.info("ERROR: No FCM token found for user", targetUid);
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
          workerId: targetUid,
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

// Notify worker when a new booking is created
export const sendBookingRequestNotification = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    logger.info(
      "=== CLOUD FUNCTION sendBookingRequestNotification TRIGGERED ===",
    );
    logger.info("Booking ID:", event.params.bookingId);

    const booking = event.data?.data();
    if (!booking) {
      logger.info("ERROR: Booking data is null");
      return;
    }

    const workerUid = (booking.workerUid as string | undefined) ?? "";
    if (!workerUid.trim()) {
      logger.info("ERROR: Missing workerUid on booking");
      return;
    }

    const employerId = (booking.employerId as string | undefined) ?? "";
    const employerNameFallback =
      (booking.employerName as string | undefined) ?? "an employer";

    let employerName = employerNameFallback;
    if (employerId.trim()) {
      try {
        const employerDoc = await admin
          .firestore()
          .collection("Sign Up")
          .doc(employerId)
          .get();
        if (employerDoc.exists) {
          const fullName = employerDoc.data()?.fullName;
          if (typeof fullName === "string" && fullName.trim()) {
            employerName = fullName.trim();
          }
        }
      } catch (error) {
        logger.info("ERROR fetching employer name:", error);
      }
    }

    try {
      const workerDoc = await admin
        .firestore()
        .collection("users")
        .doc(workerUid)
        .get();

      if (!workerDoc.exists) {
        logger.info("ERROR: Worker document does not exist", workerUid);
        return;
      }

      const fcmToken = workerDoc.data()?.fcmToken as string | undefined;
      if (!fcmToken) {
        logger.info("ERROR: No FCM token found for worker", workerUid);
        return;
      }

      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "New Booking Request",
          body: `${employerName} booked you. View the booking request.`,
        },
        data: {
          type: "booking_request",
          bookingId: event.params.bookingId,
          employerName: employerName,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "bookings",
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

      logger.info("SUCCESS: Booking request notification sent", {
        bookingId: event.params.bookingId,
        workerUid,
      });
    } catch (error) {
      logger.info("ERROR sending booking request notification:", error);
    }
  },
);

// Notify employer when a worker accepts a booking
export const sendBookingAcceptedNotification = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) {
      return;
    }

    const beforeStatus = String(before.status || "");
    const afterStatus = String(after.status || "");
    if (beforeStatus === afterStatus || afterStatus !== "confirmed") {
      return;
    }

    const employerId = (after.employerId as string | undefined) ?? "";
    const workerUid = (after.workerUid as string | undefined) ?? "";
    if (!employerId.trim()) {
      logger.info("Booking accepted notification skipped: missing employerId");
      return;
    }

    const db = admin.firestore();

    let workerName = "Worker";
    if (workerUid.trim()) {
      try {
        const workerDoc = await db.collection("Sign Up").doc(workerUid).get();
        if (workerDoc.exists) {
          const fullName = workerDoc.data()?.fullName;
          if (typeof fullName === "string" && fullName.trim()) {
            workerName = fullName.trim();
          }
        }
      } catch (error) {
        logger.info("ERROR fetching worker name:", error);
      }
    }

    let employerFcmToken: string | undefined;
    const employerUsersDoc = await db.collection("users").doc(employerId).get();
    if (employerUsersDoc.exists) {
      employerFcmToken = employerUsersDoc.data()?.fcmToken as
        | string
        | undefined;
    }

    if (!employerFcmToken) {
      const employerSignUpDoc = await db
        .collection("Sign Up")
        .doc(employerId)
        .get();
      if (employerSignUpDoc.exists) {
        employerFcmToken = employerSignUpDoc.data()?.fcmToken as
          | string
          | undefined;
      }
    }

    await db.collection("notifications").add({
      toUserId: employerId,
      fromUserId: workerUid || "system",
      title: "Booking accepted",
      message: `${workerName} accepted your booking request.`,
      type: "booking_accepted",
      bookingId: event.params.bookingId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (!employerFcmToken) {
      logger.info("Booking accepted push skipped: no FCM token", {
        employerId,
      });
      return;
    }

    try {
      await admin.messaging().send({
        token: employerFcmToken,
        notification: {
          title: "Booking accepted",
          body: `${workerName} accepted your booking request.`,
        },
        data: {
          type: "booking_accepted",
          bookingId: event.params.bookingId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "bookings",
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

      logger.info("SUCCESS: Booking accepted notification sent", {
        bookingId: event.params.bookingId,
        employerId,
      });
    } catch (error) {
      logger.info("ERROR sending booking accepted notification:", error);
    }
  },
);

// Cancel booking with escrow refund and cancellation fee
export const cancelBookingWithEscrow = onCall(async (request) => {
  logger.info("DEBUG: cancelBookingWithEscrow called", {
    data: request.data,
    uid: request.auth?.uid,
  });

  try {
    const { bookingId } = request.data;
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "bookingId is required");
    }

    const callerId = request.auth?.uid as string | undefined;
    if (!callerId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const db = admin.firestore();
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const booking = bookingSnap.data() as {
      employerId?: string;
      workerUid?: string;
      status?: string;
      amount?: number;
      escrowId?: string;
      employerPhone?: string;
    };

    const employerId = (booking.employerId ?? "").toString();
    const workerUid = (booking.workerUid ?? "").toString();
    if (!employerId || !workerUid) {
      throw new HttpsError(
        "failed-precondition",
        "Booking missing employer or worker",
      );
    }
    if (callerId !== employerId && callerId !== workerUid) {
      throw new HttpsError(
        "permission-denied",
        "You are not allowed to cancel this booking",
      );
    }

    const receiverId = callerId === employerId ? workerUid : employerId;
    if (!receiverId) {
      throw new HttpsError(
        "failed-precondition",
        "Receiver is missing for this booking",
      );
    }

    const addRoleNotification = async (
      role: "employer" | "worker",
      userId: string,
      title: string,
      message: string,
      type: string,
    ) => {
      const collectionName =
        role === "employer" ? "EmployerNotifications" : "WorkerNotifications";
      const userKey = role === "employer" ? "employerId" : "workerId";
      await db.collection(collectionName).add({
        [userKey]: userId,
        title,
        message,
        type,
        bookingId,
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    };

    const notifyCancellationCode = async (code: string) => {
      const receiverDoc = await db.collection("Sign Up").doc(receiverId).get();
      const fcmToken = receiverDoc.data()?.fcmToken as string | undefined;
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "Cancellation Code",
            body: `Your cancellation code is ${code}`,
          },
          data: {
            type: "escrow_cancellation_code",
            bookingId,
            cancellationCode: code,
          },
        });
      }

      const requesterRole = callerId === employerId ? "employer" : "worker";
      const receiverRole = requesterRole === "employer" ? "worker" : "employer";
      const requesterId = callerId === employerId ? employerId : workerUid;

      await addRoleNotification(
        requesterRole,
        requesterId,
        "Cancellation Requested",
        "Cancellation requested. Waiting for code entry.",
        "escrow_cancellation_requested",
      );
      await addRoleNotification(
        receiverRole,
        receiverId,
        "Cancellation Code",
        `Your cancellation code is ${code}`,
        "escrow_cancellation_code",
      );
    };

    let escrowRef: admin.firestore.DocumentReference | null = null;
    let escrowData: admin.firestore.DocumentData | undefined;

    const escrowId = (booking.escrowId ?? "").toString();
    if (escrowId.trim()) {
      escrowRef = db.collection("Escrow").doc(escrowId);
      const escrowSnap = await escrowRef.get();
      if (escrowSnap.exists) {
        escrowData = escrowSnap.data();
      }
    }

    if (!escrowData) {
      const escrowQuery = await db
        .collection("Escrow")
        .where("bookingId", "==", bookingId)
        .limit(1)
        .get();
      if (!escrowQuery.empty) {
        escrowRef = escrowQuery.docs[0].ref;
        escrowData = escrowQuery.docs[0].data();
      }
    }

    if (!escrowRef || !escrowData) {
      throw new HttpsError(
        "failed-precondition",
        "Escrow record not found for this booking",
      );
    }

    const escrowAmountRaw = escrowData.amount ?? booking.amount ?? 0;
    const escrowAmount = Math.max(0, Math.round(Number(escrowAmountRaw)));
    const feeAmount = Math.round(escrowAmount * 0.005);
    const refundAmount = Math.max(0, escrowAmount - feeAmount);

    const existingStatus = (escrowData.cancellationStatus ?? "").toString();
    const existingCode = (escrowData.cancellationCode ?? "").toString();
    if (existingStatus === "pending" && existingCode) {
      await notifyCancellationCode(existingCode);
      return {
        success: true,
        message: "Cancellation already pending",
        cancellationCode: existingCode,
      };
    }

    if (existingStatus === "verified") {
      return { success: true, message: "Cancellation already verified" };
    }

    const cancellationCode = Math.floor(
      100000 + Math.random() * 900000,
    ).toString();

    await db.runTransaction(async (tx) => {
      const escrowSnap = await tx.get(
        escrowRef as admin.firestore.DocumentReference,
      );
      if (!escrowSnap.exists) {
        throw new HttpsError("failed-precondition", "Escrow record not found");
      }

      const currentEscrow = escrowSnap.data() as {
        inEscrow?: boolean;
      };
      if (currentEscrow.inEscrow === false) {
        throw new HttpsError("failed-precondition", "Escrow already released");
      }

      tx.update(escrowRef as admin.firestore.DocumentReference, {
        feeAmount: feeAmount,
        refundAmount: refundAmount,
        feeStatus: feeAmount > 0 ? "PENDING" : "NOT_REQUIRED",
        cancellationCode: cancellationCode,
        cancellationStatus: "pending",
        cancellationRequestedBy: callerId,
        cancellationReceiverId: receiverId,
        cancellationRequestedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(bookingRef, {
        status: "cancellation_pending",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledBy: callerId,
        cancellationFee: feeAmount,
        escrowRefund: refundAmount,
      });
    });

    await notifyCancellationCode(cancellationCode);

    return { success: true, feeAmount, refundAmount };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    logger.error("cancelBookingWithEscrow error:", errorMessage);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      `Failed to cancel booking: ${errorMessage}`,
    );
  }
});

// Verify cancellation code and release escrow
export const verifyEscrowCancellationCode = onCall(async (request) => {
  try {
    const { bookingId, code } = request.data;
    if (!bookingId || !code) {
      throw new HttpsError(
        "invalid-argument",
        "bookingId and code are required",
      );
    }

    const callerId = request.auth?.uid as string | undefined;
    if (!callerId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const db = admin.firestore();
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const booking = bookingSnap.data() as {
      amount: any;
      employerId?: string;
      workerUid?: string;
      escrowId?: string;
    };

    const employerId = (booking.employerId ?? "").toString();
    const workerUid = (booking.workerUid ?? "").toString();
    if (callerId !== employerId && callerId !== workerUid) {
      throw new HttpsError(
        "permission-denied",
        "You are not allowed to verify this booking",
      );
    }

    let escrowRef: admin.firestore.DocumentReference | null = null;
    let escrowData: admin.firestore.DocumentData | undefined;

    const escrowId = (booking.escrowId ?? "").toString();
    if (escrowId.trim()) {
      escrowRef = db.collection("Escrow").doc(escrowId);
      const escrowSnap = await escrowRef.get();
      if (escrowSnap.exists) {
        escrowData = escrowSnap.data();
      }
    }

    if (!escrowData) {
      const escrowQuery = await db
        .collection("Escrow")
        .where("bookingId", "==", bookingId)
        .limit(1)
        .get();
      if (!escrowQuery.empty) {
        escrowRef = escrowQuery.docs[0].ref;
        escrowData = escrowQuery.docs[0].data();
      }
    }

    if (!escrowRef || !escrowData) {
      throw new HttpsError(
        "failed-precondition",
        "Escrow record not found for this booking",
      );
    }

    const storedCode = (escrowData.cancellationCode ?? "").toString();
    const status = (escrowData.cancellationStatus ?? "").toString();
    const receiverId = (escrowData.cancellationReceiverId ?? "").toString();
    const cancellationRequestedBy = (
      escrowData.cancellationRequestedBy ?? ""
    ).toString();

    if (status === "verified") {
      return { success: true, message: "Cancellation already verified" };
    }

    if (receiverId && receiverId !== callerId) {
      throw new HttpsError(
        "permission-denied",
        "You are not the intended recipient of this code",
      );
    }

    if (!storedCode || storedCode !== String(code)) {
      throw new HttpsError("invalid-argument", "Invalid cancellation code");
    }

    const escrowAmountRaw = escrowData.amount ?? booking.amount ?? 0;
    const escrowAmount = Math.max(0, Math.round(Number(escrowAmountRaw)));
    const feeAmount = Math.round(escrowAmount * 0.005);
    const refundAmount = Math.max(0, escrowAmount - feeAmount);

    const employerRef = db.collection("Sign Up").doc(employerId);
    const penaltiesRef = db.collection("Penalties").doc();

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(escrowRef as admin.firestore.DocumentReference);
      if (!snap.exists) {
        throw new HttpsError("failed-precondition", "Escrow record not found");
      }

      tx.update(escrowRef as admin.firestore.DocumentReference, {
        inEscrow: false,
        isPaid: false,
        amount: refundAmount,
        cancellationStatus: "verified",
        cancellationVerifiedBy: callerId,
        cancellationVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        cancellationCode: admin.firestore.FieldValue.delete(),
        feeAmount: feeAmount,
        refundAmount: refundAmount,
        penaltyAmount: feeAmount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(bookingRef, {
        status: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        inEscrow: false,
      });

      tx.update(employerRef, {
        amount: admin.firestore.FieldValue.increment(refundAmount),
      });

      tx.set(penaltiesRef, {
        bookingId: bookingId,
        escrowId: escrowRef?.id ?? "",
        employerId: employerId,
        workerUid: workerUid,
        amount: feeAmount,
        reason: "cancellation_penalty",
        cancellationRequestedBy: cancellationRequestedBy,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    const addRoleNotification = async (
      role: "employer" | "worker",
      userId: string,
      title: string,
      message: string,
      type: string,
    ) => {
      const collectionName =
        role === "employer" ? "EmployerNotifications" : "WorkerNotifications";
      const userKey = role === "employer" ? "employerId" : "workerId";
      await db.collection(collectionName).add({
        [userKey]: userId,
        title,
        message,
        type,
        bookingId,
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    };

    await addRoleNotification(
      "employer",
      employerId,
      "Cancellation Verified",
      "Cancellation completed. Escrow refunded to employer.",
      "escrow_cancellation_verified",
    );
    await addRoleNotification(
      "worker",
      workerUid,
      "Cancellation Verified",
      "Cancellation completed. Escrow refunded to employer.",
      "escrow_cancellation_verified",
    );

    return { success: true };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    logger.error("verifyEscrowCancellationCode error:", errorMessage);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      `Failed to verify cancellation code: ${errorMessage}`,
    );
  }
});

// Notify user when a payment transitions to SUCCESS
export const notifyPaymentSuccess = onDocumentUpdated(
  "Payment Data/{paymentId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      return;
    }

    const prevStatus = String(beforeData.status || "");
    const nextStatus = String(afterData.status || "");

    if (prevStatus == nextStatus || nextStatus != "SUCCESS") {
      return;
    }

    const userId = afterData.userId as string | undefined;
    if (!userId) {
      logger.warn("Payment success notification skipped: missing userId");
      return;
    }

    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();
    if (!userDoc.exists) {
      logger.warn("Payment success notification skipped: user not found", {
        userId,
      });
      return;
    }

    const fcmToken = userDoc.data()?.fcmToken as string | undefined;
    if (!fcmToken) {
      logger.warn("Payment success notification skipped: no FCM token", {
        userId,
      });
      return;
    }

    const amount = afterData.amount ?? "";

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Payment Successful",
        body: `Your payment of ${amount} has been added made successfully!`,
      },
      data: {
        type: "payment_success",
        amount: String(amount),
      },
    });

    logger.info("Payment success notification sent", { userId });
  },
);

// Notify user when a withdrawal transitions to SUCCESS
export const notifyWithdrawalSuccess = onDocumentUpdated(
  "Withdrawals/{withdrawalId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      return;
    }

    const prevStatus = String(beforeData.status || "");
    const nextStatus = String(afterData.status || "");

    if (prevStatus == nextStatus || nextStatus != "SUCCESS") {
      return;
    }

    const userId = afterData.userId as string | undefined;
    if (!userId) {
      logger.warn("Withdrawal success notification skipped: missing userId");
      return;
    }

    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();
    if (!userDoc.exists) {
      logger.warn("Withdrawal success notification skipped: user not found", {
        userId,
      });
      return;
    }

    const fcmToken = userDoc.data()?.fcmToken as string | undefined;
    if (!fcmToken) {
      logger.warn("Withdrawal success notification skipped: no FCM token", {
        userId,
      });
      return;
    }

    const amount = afterData.amount ?? "";

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Withdrawal Successful",
        body: `You have withdrawn ${amount} to your mobile money`,
      },
      data: {
        type: "withdrawal_success",
        amount: String(amount),
      },
    });

    logger.info("Withdrawal success notification sent", { userId });
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
        res
          .status(400)
          .json({ success: false, message: "Missing msisdn or userId" });
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
        logger.info("DEBUG: Failed Airtel prefix check", {
          msisdn: normalizedMsisdn,
        });
        res.json({
          success: false,
          message: "Please enter a valid Airtel Uganda number",
        });
        return;
      }

      // 3. Verify the user exists in your "Sign Up" collection
      const userDoc = await admin
        .firestore()
        .collection("Sign Up")
        .doc(userId)
        .get();
      if (!userDoc.exists) {
        logger.warn("DEBUG: User not found", { userId });
        res
          .status(403)
          .json({ success: false, message: "User not registered" });
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
            Accept: "application/vnd.relworx.v2",
            Authorization: `Bearer ${apiKey}`, // ✅ FIXED: Must be Bearer
          },
        },
      );

      logger.info("DEBUG: Relworx Response", response.data);

      const responseData = response.data as { customer_name?: string };

      if (responseData.customer_name) {
        res.json({
          success: true,
          customer_name: responseData.customer_name,
        });
      } else {
        res.json({
          success: false,
          message: "Mobile number is invalid or not registered",
        });
      }
    } catch (error: any) {
      logger.error("DEBUG: Main Error", {
        msg: error.message,
        relworxMsg: error.response?.data,
      });

      const errorMessage =
        error.response?.data?.message ||
        "Validation service currently unavailable";
      res.status(200).json({ success: false, message: errorMessage });
    }
  },
);

// Function to validate an MTN Uganda mobile number via Relworx
export const validateMtnMobileNumber = onRequest(
  {
    cors: true,
    maxInstances: 10,
  },
  async (req, res) => {
    logger.info("DEBUG: MTN Validation request received", { body: req.body });

    try {
      const { msisdn, userId } = req.body;

      if (!msisdn || !userId) {
        res
          .status(400)
          .json({ success: false, message: "Missing msisdn or userId" });
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

      // 2. Local Regex for MTN Uganda prefixes (77, 78, 76, 79, 31, 39)
      const mtnRegex = /^\+256(77|78|76|79|31|39)\d{7}$/;
      if (!mtnRegex.test(normalizedMsisdn)) {
        logger.info("DEBUG: Failed MTN prefix check", {
          msisdn: normalizedMsisdn,
        });
        res.json({
          success: false,
          message: "Please enter a valid MTN Uganda number",
        });
        return;
      }

      // 3. Verify the user exists in your "Sign Up" collection
      const userDoc = await admin
        .firestore()
        .collection("Sign Up")
        .doc(userId)
        .get();
      if (!userDoc.exists) {
        logger.warn("DEBUG: User not found", { userId });
        res
          .status(403)
          .json({ success: false, message: "User not registered" });
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
            Accept: "application/vnd.relworx.v2",
            Authorization: `Bearer ${apiKey}`, // ✅ FIXED: Must be Bearer
          },
        },
      );

      logger.info("DEBUG: Relworx Response", response.data);

      const responseData = response.data as { customer_name?: string };

      if (responseData.customer_name) {
        res.json({
          success: true,
          customer_name: responseData.customer_name,
        });
      } else {
        res.json({
          success: false,
          message: "Mobile number is invalid or not registered",
        });
      }
    } catch (error: any) {
      logger.error("DEBUG: Main Error", {
        msg: error.message,
        relworxMsg: error.response?.data,
      });

      const errorMessage =
        error.response?.data?.message ||
        "Validation service currently unavailable";
      res.status(200).json({ success: false, message: errorMessage });
    }
  },
);

// Function to request payment (Fixed Version)
export const requestPayment = onCall(async (request) => {
  logger.info("DEBUG: Payment request started", { data: request.data });

  try {
    // 1. Extract data from request.data
    const {
      userId,
      msisdn,
      amount,
      reference,
      description,
      originalPhoneNumber,
      saveCard,
    } = request.data;

    logger.info("DEBUG: Extracted data", {
      userId,
      msisdn,
      amount,
      reference,
      description,
      saveCard,
    });

    // 2. Basic Validation
    if (!userId || !msisdn || !amount || !reference) {
      logger.info("DEBUG: Missing required fields", {
        userId: !!userId,
        msisdn: !!msisdn,
        amount: !!amount,
        reference: !!reference,
      });
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields: userId, msisdn, amount, or reference",
      );
    }

    logger.info("DEBUG: Basic validation passed");

    // 3. Verify user in "Sign Up" collection
    logger.info("DEBUG: Checking user in Sign Up collection", { userId });
    const userDoc = await admin
      .firestore()
      .collection("Sign Up")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      logger.info("DEBUG: User not found in Sign Up collection", { userId });
      throw new HttpsError(
        "permission-denied",
        "User not registered in Sign Up records",
      );
    }

    logger.info("DEBUG: User verification passed");

    // 4. Prepare Relworx API call & FIX REFERENCE LENGTH
    const apiUrl = `${process.env.RELWORX_BASE_URL}/mobile-money/request-payment`;
    const apiKey = process.env.RELWORX_API_KEY;
    const accountNo = process.env.RELWORX_ACCOUNT_NO;

    // FIX: Relworx requires reference to be 8-36 chars.
    // We prefix and pad if it's too short (e.g., "123" becomes "REF-TXN-123")
    const finalReference =
      reference.toString().length < 8
        ? `REF-TXN-${reference}`.padEnd(10, "0")
        : reference.toString();

    const requestData = {
      account_no: accountNo,
      reference: finalReference,
      msisdn: msisdn, // Ensure this is +256 format
      currency: "UGX",
      amount: amount,
      description: description || "Service Payment",
      webhook_url: process.env.RELWORX_WEBHOOK_URL,
    };

    logger.info("DEBUG: Sending request to Relworx", { finalReference });

    // 5. Execute Relworx Request
    const response = await axios.post(apiUrl, requestData, {
      headers: {
        "Content-Type": "application/json",
        Accept: "application/vnd.relworx.v2",
        Authorization: `Bearer ${apiKey}`,
      },
    });

    const responseData = response.data as { internal_reference?: string };

    // 6. Save Record to "Payment Data" collection
    const paymentRecord = {
      userId: userId,
      msisdn: msisdn,
      amount: amount,
      reference: finalReference, // Save the actual reference sent to Relworx
      description: description || "Service Payment",
      status: "PENDING_USER_CONFIRMATION",
      relworx_internal_ref: responseData.internal_reference || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin.firestore().collection("Payment Data").add(paymentRecord);

    // 7. Save Number if requested
    if (saveCard && originalPhoneNumber) {
      await admin
        .firestore()
        .collection("Saved Payment Methods")
        .doc(userId)
        .collection("Airtel Numbers")
        .doc("latest")
        .set({
          phoneNumber: originalPhoneNumber,
          savedAt: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
        });
    }

    logger.info(`Payment prompt sent successfully for ${userId}`);

    // Return success response
    return {
      success: true,
      message: "Payment prompt sent to phone",
      relworx_data: responseData,
    };
  } catch (error: any) {
    // Better error logging to see exactly what Relworx says
    const errorDetails = error.response?.data || error.message;
    logger.error("Payment Request Error:", errorDetails);

    const errorMessage = error.response?.data?.message || error.message;
    throw new HttpsError("internal", `Payment Failed: ${errorMessage}`);
  }
});

// Function to handle Withdrawals (Payouts)
export const requestWithdrawal = onCall(async (request) => {
  logger.info("DEBUG: Withdrawal request started", { data: request.data });

  try {
    const { userId, msisdn, amount, reference, description } = request.data;

    // 1. Basic Validation
    if (!userId || !msisdn || !amount || !reference) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    // 2. Security Check: Verify User 'amount' in Firestore
    const userRef = admin.firestore().collection("Sign Up").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found.");
    }

    const userData = userDoc.data();
    // CHANGED: Use 'amount' instead of 'balance'
    const currentUserFunds = userData?.amount || 0;

    if (currentUserFunds < amount) {
      throw new HttpsError(
        "failed-precondition",
        "Insufficient funds for withdrawal.",
      );
    }

    // 3. Prepare Relworx API call
    const apiUrl = `${process.env.RELWORX_BASE_URL}/mobile-money/send-payment`;
    const apiKey = process.env.RELWORX_API_KEY;
    const accountNo = process.env.RELWORX_ACCOUNT_NO;

    // Sanitize Reference (8-36 chars)
    const finalReference =
      reference.toString().length < 8
        ? `WD-TXN-${reference}`.padEnd(10, "0")
        : reference.toString().substring(0, 36);

    const requestData = {
      account_no: accountNo,
      reference: finalReference,
      msisdn: msisdn, // Must be +256...
      currency: "UGX",
      amount: Math.round(Number(amount)), // Ensure integer
      description: description || "Wallet Withdrawal",
      webhook_url: process.env.RELWORX_WEBHOOK_URL,
    };

    logger.info("DEBUG: Sending Withdrawal to Relworx", {
      finalReference,
      amount,
    });

    // 4. Execute Relworx Request
    const response = await axios.post(apiUrl, requestData, {
      headers: {
        "Content-Type": "application/json",
        Accept: "application/vnd.relworx.v2",
        Authorization: `Bearer ${apiKey}`,
      },
    });

    const responseData = response.data as { internal_reference?: string };

    // 5. Update Local Firestore (Deduct 'amount' & Log)
    const batch = admin.firestore().batch();

    // Deduct from user's 'amount' field
    batch.update(userRef, {
      amount: admin.firestore.FieldValue.increment(-amount),
    });

    // Save transaction record
    const withdrawalRecord = {
      userId,
      msisdn,
      amount,
      reference: finalReference,
      type: "WITHDRAWAL",
      status: "PROCESSING",
      relworx_internal_ref: responseData.internal_reference || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const transRef = admin.firestore().collection("Withdrawals").doc();
    batch.set(transRef, withdrawalRecord);

    await batch.commit();

    return {
      success: true,
      message: "Withdrawal is being processed",
      relworx_data: responseData,
    };
  } catch (error: any) {
    const errorDetails = error.response?.data || error.message;
    logger.error("Withdrawal Error:", errorDetails);

    const errorMessage = error.response?.data?.message || error.message;
    throw new HttpsError("internal", `Withdrawal Failed: ${errorMessage}`);
  }
});

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

export const paymentWebhook = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const {
      status, // Relworx uses 'success', 'failed', or 'cancelled'
      message,
      internal_reference, // Relworx internal reference
      reference, // Relworx may send this
      customer_reference, // Relworx commonly sends this
      completed_at,
    } = req.body;

    const lookupReference = reference || customer_reference;

    if (!internal_reference) {
      logger.error("Webhook Error: No internal_reference found in payload");
      res.status(400).send("Missing internal_reference");
      return;
    }

    if (!lookupReference) {
      logger.error("Webhook Error: No reference found in payload");
      res.status(400).send("Missing reference");
      return;
    }

    const normalizedStatus = String(status || "").toLowerCase();

    logger.info(
      `Processing Webhook for Ref: ${internal_reference} | Status: ${status}`,
    );

    // 1. Query for the document where reference matches the reference from payload
    const querySnapshot = await admin
      .firestore()
      .collection("Payment Data")
      .where("reference", "==", lookupReference)
      .get();

    if (querySnapshot.empty) {
      logger.warn(
        `Webhook received for unknown transaction: ${internal_reference}`,
      );
      // We return 200 so Relworx stops retrying, but we log the warning
      res.status(200).send("Transaction not found in our records");
      return;
    }

    // Assuming only one document matches, get the first one
    const doc = querySnapshot.docs[0];
    const paymentDocRef = doc.ref;

    // 3. Update the existing document
    await paymentDocRef.update({
      status: String(status || "").toUpperCase(), // Store as SUCCESS or FAILED
      relworx_internal_ref: internal_reference, // Set it now
      relworx_final_message: message,
      completedAt: completed_at
        ? admin.firestore.Timestamp.fromDate(new Date(completed_at))
        : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      raw_webhook_payload: req.body, // Good for debugging later
    });

    // 4. Handle logical success (e.g. giving the user their credits/items)
    if (normalizedStatus === "success") {
      const paymentData = doc.data();
      logger.info(`Finalizing value for User: ${paymentData?.userId}`);

      // Update user's balance in Sign Up collection
      if (paymentData?.userId && paymentData?.amount) {
        const depositAmount = Math.round(Number(paymentData.amount));
        await admin
          .firestore()
          .collection("Sign Up")
          .doc(paymentData.userId)
          .update({
            amount: admin.firestore.FieldValue.increment(depositAmount),
          });
        logger.info(
          `Updated balance for user ${paymentData.userId} by ${depositAmount}`,
        );
      }
    }

    res.status(200).send("OK");
  } catch (error) {
    logger.error("Webhook processing failed:", error);
    res.status(500).send("Internal Server Error");
  }
});

export const masterWebhook = onRequest({ cors: true }, async (req, res) => {
  try {
    // 1. Handshake for Relworx Dashboard validation
    if (req.method === "GET") {
      res.status(200).send("Webhook active");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const {
      status,
      message,
      internal_reference,
      reference, // This is the 'finalReference' we created in our functions
      completed_at,
    } = req.body;

    if (!internal_reference) {
      logger.error("Webhook Error: No internal_reference found in payload");
      res.status(400).send("Missing internal_reference");
      return;
    }

    logger.info(
      `Master Webhook: Ref ${internal_reference} | Status: ${status}`,
    );

    // 2. SEARCH: Look for the transaction in both collections
    const collections = ["Payment Data", "Withdrawals"];
    let targetDoc: admin.firestore.QueryDocumentSnapshot | null = null;
    let foundIn = "";

    for (const col of collections) {
      const querySnapshot = await admin
        .firestore()
        .collection(col)
        .where("reference", "==", reference)
        .limit(1)
        .get();

      if (!querySnapshot.empty) {
        targetDoc = querySnapshot.docs[0];
        foundIn = col;
        break;
      }
    }

    if (!targetDoc) {
      logger.warn(
        `Webhook received for unknown transaction reference: ${reference}`,
      );
      res.status(200).send("OK"); // Respond 200 so Relworx stops retrying
      return;
    }

    const docRef = targetDoc.ref;
    const transData = targetDoc.data();
    const normalizedStatus = status.toLowerCase();

    // 3. UPDATE: Update the transaction record with the final status
    await docRef.update({
      status: status.toUpperCase(), // e.g., SUCCESS or FAILED
      relworx_internal_ref: internal_reference,
      relworx_final_message: message,
      completedAt: completed_at
        ? admin.firestore.Timestamp.fromDate(new Date(completed_at))
        : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      raw_webhook_payload: req.body,
    });

    // 4. LOGIC: Handle DEPOSIT Success (Add money to user balance)
    if (foundIn === "Payment Data" && normalizedStatus === "success") {
      const depositAmount = Math.round(Number(transData.amount));
      await admin
        .firestore()
        .collection("Sign Up")
        .doc(transData.userId)
        .update({
          amount: admin.firestore.FieldValue.increment(depositAmount),
        });
      logger.info(
        `DEPOSIT SUCCESS: Added ${depositAmount} to user ${transData.userId}`,
      );
    }

    // 5. LOGIC: Handle WITHDRAWAL Failure (Refund money back to user)
    if (foundIn === "Withdrawals" && normalizedStatus === "failed") {
      const refundAmount = Math.round(Number(transData.amount));
      await admin
        .firestore()
        .collection("Sign Up")
        .doc(transData.userId)
        .update({
          amount: admin.firestore.FieldValue.increment(refundAmount),
        });
      logger.info(
        `WITHDRAWAL FAILED: Refunded ${refundAmount} to user ${transData.userId}`,
      );
    }

    res.status(200).send("OK");
  } catch (error) {
    logger.error("Master Webhook processing failed:", error);
    res.status(500).send("Internal Server Error");
  }
});

//function for mastercard session request
export const requestCardSession = onRequest(async (req, res) => {
  // 1. Only allow POST requests
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const { userId, amount, reference, description } = req.body;

  logger.info("DEBUG: Card Session Request started", { userId });

  try {
    // 2. Validation
    if (!userId || !amount || !reference) {
      res.status(400).send({
        success: false,
        message: "Missing required fields (userId, amount, or reference).",
      });
      return;
    }

    // 3. Relworx Configuration
    // Ensure RELWORX_BASE_URL does not end with a slash in your Env Vars
    const apiUrl = `${process.env.RELWORX_BASE_URL}/visa/request-session`;

    // Formatting reference to meet Relworx length requirements
    const finalReference =
      reference.toString().length < 8
        ? `CARD-TXN-${reference}`.padEnd(10, "0")
        : reference.toString().substring(0, 36);

    const requestData = {
      account_no: process.env.RELWORX_ACCOUNT_NO, // Should be REL4E261389F7
      reference: finalReference,
      currency: "UGX",
      amount: Math.round(Number(amount)),
      description: description || "Registration Fee Payment",
    };

    // 4. API Call to Relworx
    const response = await axios.post(apiUrl, requestData, {
      headers: {
        "Content-Type": "application/json",
        Accept: "application/vnd.relworx.v2",
        // Ensure your API Key in Env Vars is just the string, not starting with "Bearer "
        Authorization: `Bearer ${process.env.RELWORX_API_KEY}`,
      },
    });

    const responseData = response.data as { payment_url?: string };

    // 5. Save Record to Firestore
    await admin.firestore().collection("Payment Data").doc(finalReference).set({
      userId: userId,
      amount: requestData.amount,
      reference: finalReference,
      status: "PENDING",
      type: "CARD",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("SUCCESS: Card Session Created", { reference: finalReference });

    res.status(200).send({
      success: true,
      payment_url: responseData.payment_url,
    });
  } catch (error: any) {
    // 6. Detailed Error Logging for Debugging FORBIDDEN_ACCESS
    const apiErrorData = error.response?.data;
    const apiStatus = error.response?.status;

    logger.error("Card Session Error Details:", {
      status: apiStatus,
      relworxResponse: apiErrorData, // This will show the EXACT reason from Relworx
      message: error.message,
      endpoint: error.config?.url,
    });

    // Return the specific error from Relworx to your frontend for easier debugging
    res.status(apiStatus || 500).send({
      success: false,
      error_code: apiErrorData?.error_code || "INTERNAL_ERROR",
      message: apiErrorData?.message || "An unexpected error occurred.",
    });
  }
});

/**
 * Cloud Function: applyReferralRewards
 * Callable function to apply referral bonuses to both referrer and referred user
 * - Reads dynamic bonus amounts from System Settings.default collection
 * - Finds the referrer by their referralCode
 * - Creates/updates Referred Users entry
 * - Atomically increments both user amounts using transactions
 */
export const applyReferralRewards = onCall(
  { maxInstances: 5 },
  async (request) => {
    try {
      const { referredUserId, referralCode } = request.data;

      // 1. Validate inputs
      if (!referredUserId || !referralCode) {
        throw new HttpsError(
          "invalid-argument",
          "referredUserId and referralCode are required",
        );
      }

      const db = admin.firestore();

      // 2. Check if referral already rewarded (prevent duplicates)
      const existingReferral = await db
        .collection("Referred Users")
        .doc(referredUserId)
        .get();

      if (existingReferral.exists) {
        const data = existingReferral.data();
        if (data?.rewarded === true) {
          return {
            success: false,
            message: "Referral reward already applied",
          };
        }
      }

      // 3. Get dynamic bonus amounts from System Settings
      const settingsSnap = await db
        .collection("System Settings")
        .doc("default")
        .get();

      if (!settingsSnap.exists) {
        throw new HttpsError("not-found", "System Settings document not found");
      }

      const settings = settingsSnap.data() as {
        referralBonusUG?: number;
        referrerBonus?: number;
      };
      const referredBonus = settings?.referralBonusUG ?? 500;
      const referrerBonus = settings?.referrerBonus ?? 600;

      // 4. Find the referrer by their referralCode
      const referrerSnap = await db
        .collection("Sign Up")
        .where("referralCode", "==", referralCode)
        .limit(1)
        .get();

      if (referrerSnap.empty) {
        throw new HttpsError(
          "not-found",
          `Referral code "${referralCode}" not found`,
        );
      }

      const referrerDoc = referrerSnap.docs[0];
      const referrerUserId = referrerDoc.id;
      const referrerData = referrerDoc.data();

      // Prevent self-referral
      if (referrerUserId === referredUserId) {
        throw new HttpsError("invalid-argument", "Cannot refer yourself");
      }

      // 5. Get referred user data
      const referredUserSnap = await db
        .collection("Sign Up")
        .doc(referredUserId)
        .get();

      if (!referredUserSnap.exists) {
        throw new HttpsError("not-found", "Referred user not found");
      }

      const referredUserData = referredUserSnap.data() as {
        phoneNumber?: string;
        email?: string;
        fullName?: string;
      };

      // 6. Apply rewards using transaction (atomic operation)
      await db.runTransaction(async (transaction) => {
        // Increment referrer's amount
        const referrerRef = db.collection("Sign Up").doc(referrerUserId);
        transaction.update(referrerRef, {
          amount: admin.firestore.FieldValue.increment(referrerBonus),
        });

        // Increment referred user's amount
        const referredRef = db.collection("Sign Up").doc(referredUserId);
        transaction.update(referredRef, {
          amount: admin.firestore.FieldValue.increment(referredBonus),
        });

        // Create/update Referred Users entry
        const referredUsersRef = db
          .collection("Referred Users")
          .doc(referredUserId);
        transaction.set(
          referredUsersRef,
          {
            referredUserId: referredUserId,
            referrerUserId: referrerUserId,
            referralCode: referralCode,
            referredPhone: referredUserData?.phoneNumber || "",
            referredEmail: referredUserData?.email || "",
            referredFullName: referredUserData?.fullName || "",
            referrerPhone: referrerData?.phoneNumber || "",
            referrerEmail: referrerData?.email || "",
            referrerFullName: referrerData?.fullName || "",
            referrerReward: referrerBonus,
            referredReward: referredBonus,
            rewarded: true,
            rewardedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

      logger.info(
        `Referral rewards applied: referrer=${referrerUserId} (+${referrerBonus}), referred=${referredUserId} (+${referredBonus})`,
      );

      return {
        success: true,
        message: "Referral rewards applied successfully",
        referrerBonus,
        referredBonus,
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : "Unknown error";
      logger.error("Error applying referral rewards:", errorMessage);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        `Failed to apply referral rewards: ${errorMessage}`,
      );
    }
  },
);

// Finish job with escrow - worker completes job, sends code to employer for verification
export const finishJobWithEscrow = onCall(async (request) => {
  try {
    const { bookingId } = request.data;
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "bookingId is required");
    }

    const callerId = request.auth?.uid as string | undefined;
    if (!callerId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const db = admin.firestore();
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const booking = bookingSnap.data() as {
      employerId?: string;
      workerUid?: string;
      status?: string;
      amount?: number;
      escrowId?: string;
    };

    const employerId = (booking.employerId ?? "").toString();
    const workerUid = (booking.workerUid ?? "").toString();
    if (!employerId || !workerUid) {
      throw new HttpsError(
        "failed-precondition",
        "Booking missing employer or worker",
      );
    }

    // Only worker can finish the job
    if (callerId !== workerUid) {
      throw new HttpsError(
        "permission-denied",
        "Only the worker can finish this job",
      );
    }

    const escrowId = (booking.escrowId ?? "").toString();
    if (!escrowId) {
      throw new HttpsError("failed-precondition", "Escrow ID is missing");
    }

    const escrowRef = db.collection("Escrow").doc(escrowId);
    const escrowSnap = await escrowRef.get();
    if (!escrowSnap.exists) {
      throw new HttpsError("not-found", "Escrow record not found");
    }

    // Generate 6-digit completion code
    const completionCode = Math.floor(
      100000 + Math.random() * 900000,
    ).toString();

    const addRoleNotification = async (
      role: "employer" | "worker",
      userId: string,
      title: string,
      message: string,
      type: string,
    ) => {
      const collectionName =
        role === "employer" ? "EmployerNotifications" : "WorkerNotifications";
      const userKey = role === "employer" ? "employerId" : "workerId";
      await db.collection(collectionName).add({
        [userKey]: userId,
        title,
        message,
        type,
        bookingId,
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    };

    // Notify employer with completion code
    const notifyCompletionCode = async (code: string) => {
      const employerDocSnap = await db
        .collection("Sign Up")
        .doc(employerId)
        .get();
      const fcmToken = employerDocSnap.data()?.fcmToken as string | undefined;

      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "Job Completion Code",
            body: `Worker has completed the job. Your code is ${code}`,
          },
          data: {
            type: "job_completion_code",
            bookingId,
            completionCode: code,
          },
        });
      } else {
        logger.warn(`No FCM token found for employer ${employerId}`);
      }

      await addRoleNotification(
        "employer",
        employerId,
        "Job Completion Code",
        `Worker completed the job. Your code is ${code}`,
        "job_completion_code",
      );
      await addRoleNotification(
        "worker",
        workerUid,
        "Completion Requested",
        "Completion code sent to employer.",
        "job_completion_code_sent",
      );
    };

    // Update Escrow with completion code and status
    await escrowRef.update({
      completionCode: completionCode,
      completionStatus: "pending",
      completionRequestedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send code notification to employer
    await notifyCompletionCode(completionCode);

    return {
      success: true,
      message: "Completion code sent to employer",
      completionCode: completionCode, // For testing only, should not be returned in production
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    logger.error("finishJobWithEscrow error:", errorMessage);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError("internal", `Failed to finish job: ${errorMessage}`);
  }
});

// Verify job completion code - employer verifies code to release escrow to worker
export const verifyJobCompletionCode = onCall(async (request) => {
  try {
    const { bookingId, code } = request.data;
    if (!bookingId || !code) {
      throw new HttpsError(
        "invalid-argument",
        "bookingId and code are required",
      );
    }

    const callerId = request.auth?.uid as string | undefined;
    if (!callerId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const db = admin.firestore();
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const booking = bookingSnap.data() as {
      employerId?: string;
      workerUid?: string;
      amount?: number;
      escrowId?: string;
    };

    const employerId = (booking.employerId ?? "").toString();
    const workerUid = (booking.workerUid ?? "").toString();
    if (!employerId || !workerUid) {
      throw new HttpsError(
        "failed-precondition",
        "Booking missing employer or worker",
      );
    }

    // Only employer can verify the completion
    if (callerId !== employerId) {
      throw new HttpsError(
        "permission-denied",
        "Only the employer can verify job completion",
      );
    }

    const escrowId = (booking.escrowId ?? "").toString();
    if (!escrowId) {
      throw new HttpsError("failed-precondition", "Escrow ID is missing");
    }

    const escrowRef = db.collection("Escrow").doc(escrowId);
    const escrowSnap = await escrowRef.get();
    if (!escrowSnap.exists) {
      throw new HttpsError("not-found", "Escrow record not found");
    }

    const escrow = escrowSnap.data() as {
      completionCode?: string;
      completionStatus?: string;
      amount?: number;
      inEscrow?: boolean;
      isPaid?: boolean;
    };

    // Verify code
    if (escrow.completionCode !== code) {
      throw new HttpsError("invalid-argument", "Incorrect completion code");
    }

    if (escrow.completionStatus === "completed") {
      return { success: true, message: "Job already completed" };
    }

    const amount = escrow.amount || booking.amount || 0;

    // Release escrow to worker - update both Escrow record and worker's Sign Up amount
    await db.runTransaction(async (tx) => {
      // Update Escrow record
      tx.update(escrowRef, {
        inEscrow: false,
        isPaid: true,
        completionStatus: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Add amount to worker's balance in Sign Up collection
      const workerRef = db.collection("Sign Up").doc(workerUid);
      tx.update(workerRef, {
        amount: admin.firestore.FieldValue.increment(amount),
      });

      // Update booking status to completed
      tx.update(bookingRef, {
        status: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    const addRoleNotification = async (
      role: "employer" | "worker",
      userId: string,
      title: string,
      message: string,
      type: string,
    ) => {
      const collectionName =
        role === "employer" ? "EmployerNotifications" : "WorkerNotifications";
      const userKey = role === "employer" ? "employerId" : "workerId";
      await db.collection(collectionName).add({
        [userKey]: userId,
        title,
        message,
        type,
        bookingId,
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    };

    await addRoleNotification(
      "employer",
      employerId,
      "Job Completed",
      "Job completion verified. Payment released to worker.",
      "job_completed",
    );
    await addRoleNotification(
      "worker",
      workerUid,
      "Job Completed",
      "Job completion verified. Payment released to you.",
      "job_completed",
    );

    logger.info(
      `Job completed and escrow released for booking ${bookingId}. Amount ${amount} added to worker ${workerUid}`,
    );

    return {
      success: true,
      message: "Job completion verified. Amount released to worker.",
      amount: amount,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    logger.error("verifyJobCompletionCode error:", errorMessage);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      `Failed to verify completion code: ${errorMessage}`,
    );
  }
});
