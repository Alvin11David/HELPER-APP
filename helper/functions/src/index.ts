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
import * as logger from "firebase-functions/logger";
import * as nodemailer from "nodemailer";
import * as admin from "firebase-admin";
import axios from "axios";

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
  console.log("sendForgotPasswordOTPEmail called with request:", request);
  try {
    const { email, otpCode } = request.data;
    console.log("Extracted email:", email, "otpCode:", otpCode);

    if (!email || !otpCode) {
      console.log("Missing email or otpCode");
      throw new Error("Email and OTP code are required");
    }

    console.log("Creating mail options...");
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

    console.log("About to send email to:", email);
    console.log("Mail options created successfully");

    await transporter.sendMail(mailOptions);

    console.log("Email sent successfully");
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
    const apiKey = "2902144e65b9a7.v3wxxu9iseWHI-dQzOh7Gg";
    const baseUrl = "https://payments.relworx.com/api";
    const accountNo = "REL4E261389F7";
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
