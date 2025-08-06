/* eslint-disable max-len, indent, @typescript-eslint/no-explicit-any, valid-jsdoc, eol-last */

/**
 * Generation 2 Firebase Functions with HTTPS endpoints and Stripe Integration
 */

import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import Stripe from "stripe";
import cors from "cors";

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Define secrets properly for Firebase Functions v2
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

// Enhanced CORS configuration for HTTP functions
const corsHandler = cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:5000', 
    'http://localhost:8080',
    'https://theorie-3ef8a.web.app',
    'https://theorie-3ef8a.firebaseapp.com',
    // GitLab Pages - ADD YOUR ACTUAL URL
    'https://theorie-ad84fe.gitlab.io',           // Your GitLab Pages URL
    /localhost:\d+/,
    /\.web\.app$/,
    /\.firebaseapp\.com$/
  ],
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Firebase-Instance-ID-Token'],
  maxAge: 86400 // 24 hours
});

/**
 * Helper function to initialize Stripe inside function calls
 */
function getStripeInstance(): Stripe {
  return new Stripe(stripeSecretKey.value(), {
    apiVersion: "2025-07-30.basil", // Current Stripe API version
  });
}

/**
 * Helper function to verify Firebase ID token and extract user info
 */
async function verifyAuthToken(authHeader: string | undefined): Promise<admin.auth.DecodedIdToken | null> {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const idToken = authHeader.split('Bearer ')[1];
  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    console.error('Token verification failed:', error);
    return null;
  }
}

/**
 * Helper function to handle CORS and common request processing
 */
function handleRequest(
  handler: (req: any, res: any, user?: admin.auth.DecodedIdToken) => Promise<void>
) {
  return async (req: any, res: any) => {
    return corsHandler(req, res, async () => {
      // Handle preflight requests
      if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
      }

      try {
        // Verify authentication for protected endpoints
        const user = await verifyAuthToken(req.headers.authorization);
        await handler(req, res, user || undefined);
      } catch (error: any) {
        console.error('Request handler error:', error);
        res.status(500).json({
          success: false,
          error: 'Internal server error',
          message: error.message
        });
      }
    });
  };
}

/**
 * Test authentication endpoint - HTTPS
 */
export const testAuth = onRequest(
  {
    cors: false, // Handled manually
    invoker: "public",
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  handleRequest(async (req, res, user) => {
    console.log('🔄 [testAuth] Function called');
    console.log('📋 [testAuth] Request method:', req.method);
    console.log('📋 [testAuth] Request origin:', req.headers?.origin);
    console.log('📋 [testAuth] Request user-agent:', req.headers?.['user-agent']);
    console.log('📋 [testAuth] Auth exists:', !!user);
    console.log('📋 [testAuth] User ID:', user?.uid || 'NONE');
    console.log('📋 [testAuth] Authorization header exists:', !!req.headers?.authorization);
    
    if (!user) {
      console.log('⚠️ [testAuth] No authentication found - this is OK for testing purposes');
      res.json({
        success: true,
        authenticated: false,
        message: 'Function reached successfully but no authentication provided',
        timestamp: new Date().toISOString(),
        origin: req.headers?.origin || 'unknown',
        userAgent: req.headers?.['user-agent'] || 'unknown',
        testMode: true
      });
      return;
    }
    
    console.log('✅ [testAuth] Authentication successful');
    res.json({
      success: true,
      authenticated: true,
      userId: user.uid,
      email: user.email || 'no-email',
      timestamp: new Date().toISOString(),
      origin: req.headers?.origin || 'unknown',
      testMode: false
    });
  })
);

/**
 * Get subscription status - HTTPS
 */
export const getSubscriptionStatus = onRequest(
  {
    cors: false, // Handled manually
    invoker: "public", 
    memory: "256MiB",
    timeoutSeconds: 30,
    secrets: [stripeSecretKey],
  },
  handleRequest(async (req, res, user) => {
    console.log('🔄 [getSubscriptionStatus] Function called');
    console.log('📋 [getSubscriptionStatus] Request method:', req.method);
    console.log('📋 [getSubscriptionStatus] Request origin:', req.headers?.origin);
    console.log('📋 [getSubscriptionStatus] Auth exists:', !!user);
    console.log('📋 [getSubscriptionStatus] User ID:', user?.uid || 'NONE');
    
    if (!user) {
      console.log('ℹ️ [getSubscriptionStatus] No authentication - returning empty subscription for testing');
      res.json({
        success: true,
        hasSubscription: false, 
        subscription: null,
        testMode: true,
        message: 'No authentication provided'
      });
      return;
    }

    try {
      const stripe = getStripeInstance();
      const userId = user.uid;
      
      console.log(`🔄 Getting subscription status for user: ${userId}`);
      
      const userDoc = await db.collection("users").doc(userId).get();
      const userData = userDoc.data();

      console.log(`📋 User document exists: ${userDoc.exists}`);
      console.log(`📋 User has stripeCustomerId: ${!!userData?.stripeCustomerId}`);

      if (!userData?.stripeCustomerId) {
        console.log(`ℹ️ No Stripe customer ID found for user ${userId}`);
        res.json({success: true, hasSubscription: false, subscription: null});
        return;
      }

      const subscriptions = await stripe.subscriptions.list({
        customer: userData.stripeCustomerId,
        status: "all",
        limit: 10,
      });

      console.log(`📋 Found ${subscriptions.data.length} subscriptions`);

      const activeSubscription = subscriptions.data.find(
        sub => ["active", "trialing"].includes(sub.status)
      );

      if (activeSubscription) {
        console.log(`✅ Active subscription found: ${activeSubscription.id} (${activeSubscription.status})`);
        res.json({
          success: true,
          hasSubscription: true,
          subscription: {
            id: activeSubscription.id,
            status: activeSubscription.status,
            tier: getSubscriptionTier(activeSubscription),
            currentPeriodStart: (activeSubscription as any).current_period_start,
            currentPeriodEnd: (activeSubscription as any).current_period_end,
            cancelAtPeriodEnd: activeSubscription.cancel_at_period_end,
            trialEnd: activeSubscription.trial_end,
          },
        });
        return;
      }

      console.log(`ℹ️ No active subscription found for user ${userId}`);
      res.json({success: true, hasSubscription: false, subscription: null});
    } catch (error: any) {
      console.error("❌ [getSubscriptionStatus] Error getting subscription status:", error);
      console.error("❌ [getSubscriptionStatus] Error type:", error.constructor.name);
      console.error("❌ [getSubscriptionStatus] Error message:", error.message);
      res.status(500).json({
        success: false,
        error: 'Unable to get subscription status',
        message: error.message
      });
    }
  })
);

export const createSubscriptionSetup = onRequest(
  {
    cors: false, // Handled manually
    invoker: "public",
    memory: "512MiB",
    timeoutSeconds: 60,
    secrets: [stripeSecretKey],
  },
  handleRequest(async (req, res, user) => {
    console.log('🚀 [createSubscriptionSetup] Function invoked');
    console.log('📋 [createSubscriptionSetup] Request method:', req.method);
    console.log('📋 [createSubscriptionSetup] Request origin:', req.headers?.origin);
    console.log('📋 [createSubscriptionSetup] Request auth exists:', !!user);
    console.log('📋 [createSubscriptionSetup] User ID:', user?.uid || 'NONE');
    console.log('📋 [createSubscriptionSetup] Request body:', JSON.stringify(req.body, null, 2));
    console.log('📋 [createSubscriptionSetup] User Agent:', req.headers?.['user-agent']);
    console.log('📋 [createSubscriptionSetup] Authorization header exists:', !!req.headers?.authorization);
    
    if (req.method !== 'POST') {
      res.status(405).json({success: false, error: 'Method not allowed'});
      return;
    }

    if (!user) {
      console.error("❌ [createSubscriptionSetup] Authentication missing");
      res.status(401).json({
        success: false,
        error: 'Authentication required',
        message: 'User must be authenticated to create subscription'
      });
      return;
    }

    try {
      // Test secret access first
      console.log('🔄 [createSubscriptionSetup] Testing secret access...');
      let stripe;
      try {
        stripe = getStripeInstance();
        console.log('✅ [createSubscriptionSetup] Stripe initialized successfully');
        console.log('📋 [createSubscriptionSetup] Stripe key starts with:', stripeSecretKey.value().substring(0, 7));
      } catch (secretError) {
        console.error('❌ [createSubscriptionSetup] Secret access failed:', secretError);
        res.status(500).json({
          success: false,
          error: 'Configuration error: Unable to access payment service'
        });
        return;
      }
      
      // Test Stripe connectivity
      console.log('🔄 [createSubscriptionSetup] Testing Stripe API connectivity...');
      try {
        await stripe.customers.list({ limit: 1 });
        console.log('✅ [createSubscriptionSetup] Stripe API connectivity confirmed');
      } catch (stripeConnectError) {
        console.error('❌ [createSubscriptionSetup] Stripe API connection failed:', stripeConnectError);
        res.status(500).json({
          success: false,
          error: 'Payment service connectivity error'
        });
        return;
      }
      
      console.log('✅ [createSubscriptionSetup] User authenticated successfully');
      console.log('📋 [createSubscriptionSetup] Auth details:', {
        uid: user.uid,
        email: user.email,
        emailVerified: user.email_verified,
      });

      // UPDATED: Extract redirect URLs from request body
      const {tier, email, name, paymentMethodId, successUrl, cancelUrl} = req.body;
      const userId = user.uid;

      console.log(`🔄 [createSubscriptionSetup] Creating subscription setup for user ${userId}, tier: ${tier}`);
      console.log(`📋 [createSubscriptionSetup] Request data:`, {
        tier, 
        email, 
        name, 
        paymentMethodId, 
        userId,
        successUrl,
        cancelUrl
      });

      // Enhanced validation with specific error messages
      if (!tier) {
        console.error("❌ [createSubscriptionSetup] Missing tier parameter");
        res.status(400).json({success: false, error: 'Subscription tier is required'});
        return;
      }
      if (!email) {
        console.error("❌ [createSubscriptionSetup] Missing email parameter");
        res.status(400).json({success: false, error: 'Email is required'});
        return;
      }
      if (typeof tier !== 'string') {
        console.error("❌ [createSubscriptionSetup] Invalid tier type:", typeof tier);
        res.status(400).json({success: false, error: 'Subscription tier must be a string'});
        return;
      }
      if (typeof email !== 'string') {
        console.error("❌ [createSubscriptionSetup] Invalid email type:", typeof email);
        res.status(400).json({success: false, error: 'Email must be a string'});
        return;
      }

      // Validate email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        console.error("❌ [createSubscriptionSetup] Invalid email format:", email);
        res.status(400).json({success: false, error: 'Invalid email format'});
        return;
      }

      console.log('✅ [createSubscriptionSetup] Input validation passed');

      // Database operations with detailed logging
      console.log('🔄 [createSubscriptionSetup] Fetching user document from Firestore...');
      let userDoc;
      let userData;
      
      try {
        userDoc = await db.collection("users").doc(userId).get();
        userData = userDoc.data();
        console.log(`📋 [createSubscriptionSetup] User document exists: ${userDoc.exists}`);
        if (userData) {
          console.log(`📋 [createSubscriptionSetup] User has stripeCustomerId: ${!!userData.stripeCustomerId}`);
          console.log(`📋 [createSubscriptionSetup] User data keys: ${Object.keys(userData)}`);
        }
      } catch (firestoreError) {
        console.error('❌ [createSubscriptionSetup] Firestore error:', firestoreError);
        res.status(500).json({success: false, error: 'Database error while fetching user data'});
        return;
      }

      // Create or get Stripe customer
      let customer: Stripe.Customer | null = null;
      
      if (userData?.stripeCustomerId) {
        console.log('🔄 [createSubscriptionSetup] Attempting to retrieve existing customer...');
        try {
          const retrievedCustomer = await stripe.customers.retrieve(userData.stripeCustomerId);
          // Type guard to check if customer is deleted
          if ('deleted' in retrievedCustomer && retrievedCustomer.deleted) {
            console.log(`⚠️ [createSubscriptionSetup] Customer was deleted, will create new one`);
            customer = null;
          } else {
            customer = retrievedCustomer as Stripe.Customer;
            console.log(`✅ [createSubscriptionSetup] Retrieved existing customer: ${customer.id}`);
            console.log(`📋 [createSubscriptionSetup] Customer email: ${customer.email}`);
            console.log(`📋 [createSubscriptionSetup] Customer name: ${customer.name}`);
          }
        } catch (stripeError) {
          console.log(`⚠️ [createSubscriptionSetup] Customer retrieval failed:`, stripeError);
          console.log(`🔄 [createSubscriptionSetup] Will create new customer instead`);
          customer = null; // Will create new customer below
        }
      }

      if (!customer) {
        console.log(`🔄 [createSubscriptionSetup] Creating new Stripe customer`);
        try {
          customer = await stripe.customers.create({
            email: email,
            name: name || email.split('@')[0],
            metadata: {firebaseUID: userId, appName: "Theorie"},
          });

          console.log(`✅ [createSubscriptionSetup] Created new customer: ${customer.id}`);
          console.log(`📋 [createSubscriptionSetup] Customer details:`, {
            id: customer.id,
            email: customer.email,
            name: customer.name,
            created: customer.created,
          });

          // Firestore update with error handling
          console.log('🔄 [createSubscriptionSetup] Saving customer ID to Firestore...');
          try {
            await db.collection("users").doc(userId).set({
              stripeCustomerId: customer.id,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              email: email,
              username: name || email.split('@')[0],
            }, { merge: true });
            
            console.log(`✅ [createSubscriptionSetup] Saved customer ID to user document`);
          } catch (firestoreUpdateError) {
            console.error('❌ [createSubscriptionSetup] Failed to save customer ID:', firestoreUpdateError);
            // Don't throw here - customer is created, continue with subscription
            console.log('⚠️ [createSubscriptionSetup] Continuing despite Firestore update failure');
          }
        } catch (customerCreateError) {
          console.error('❌ [createSubscriptionSetup] Failed to create Stripe customer:', customerCreateError);
          res.status(500).json({success: false, error: 'Failed to create customer account'});
          return;
        }
      }

      // Price ID validation with detailed logging
      console.log('🔄 [createSubscriptionSetup] Getting price ID for tier...');
      let priceId;
      try {
        priceId = getPriceId(tier);
        console.log(`💰 [createSubscriptionSetup] Using price ID: ${priceId} for tier: ${tier}`);
      } catch (priceError) {
        console.error('❌ [createSubscriptionSetup] Price ID lookup failed:', priceError);
        res.status(400).json({success: false, error: `Invalid subscription tier: ${tier}`});
        return;
      }

      // UPDATED: Pass redirect URLs to the handler functions
      if (paymentMethodId) {
        // Mobile flow: Create subscription with payment method
        console.log(`🔄 [createSubscriptionSetup] Using mobile flow with payment method: ${paymentMethodId}`);
        await handleMobileSubscriptionFlow(stripe, customer, priceId, tier, userId, paymentMethodId, res);
      } else {
        // Web flow: Create Stripe Checkout Session with dynamic URLs
        console.log(`🔄 [createSubscriptionSetup] Using web checkout flow`);
        await handleWebCheckoutFlow(stripe, customer, priceId, tier, userId, email, res, successUrl, cancelUrl);
      }
      
    } catch (error: any) {
      console.error("❌ [createSubscriptionSetup] Error creating subscription:", error);
      console.error("❌ [createSubscriptionSetup] Error type:", error.constructor.name);
      console.error("❌ [createSubscriptionSetup] Error message:", error.message);
      console.error("❌ [createSubscriptionSetup] Error stack:", error.stack);
      
      // Better error categorization and logging
      if (error.type === "StripeCardError") {
        console.log(`💳 [createSubscriptionSetup] Stripe card error: ${error.message}`);
        res.status(400).json({success: false, error: `Payment error: ${error.message}`});
      } else if (error.type === "StripeInvalidRequestError") {
        console.log(`🔧 [createSubscriptionSetup] Stripe invalid request: ${error.message}`);
        res.status(400).json({success: false, error: error.message});
      } else if (error.type === "StripeAPIError") {
        console.log(`🌐 [createSubscriptionSetup] Stripe API error: ${error.message}`);
        res.status(500).json({success: false, error: 'Payment service error. Please try again.'});
      } else if (error.type === "StripeConnectionError") {
        console.log(`🔌 [createSubscriptionSetup] Stripe connection error: ${error.message}`);
        res.status(500).json({success: false, error: 'Unable to connect to payment service. Please try again.'});
      } else if (error.type === "StripeAuthenticationError") {
        console.log(`🔑 [createSubscriptionSetup] Stripe authentication error: ${error.message}`);
        res.status(500).json({success: false, error: 'Payment service authentication error'});
      } else if (error.message?.includes("No such price")) {
        console.log(`💰 [createSubscriptionSetup] Invalid price ID for tier: ${req.body?.tier}`);
        res.status(400).json({success: false, error: `Invalid price configuration for tier: ${req.body?.tier}`});
      } else if (error.message?.includes("No such customer")) {
        console.log(`👤 [createSubscriptionSetup] Customer account error`);
        res.status(400).json({success: false, error: 'Customer account error. Please try again.'});
      } else {
        console.log(`❓ [createSubscriptionSetup] Unknown error type: ${error.constructor.name}`);
        res.status(500).json({success: false, error: `Subscription setup failed: ${error.message || 'Unknown error'}`});
      }
    }
  })
);

/**
 * Handle mobile subscription flow with payment method
 */
async function handleMobileSubscriptionFlow(
  stripe: Stripe,
  customer: Stripe.Customer,
  priceId: string,
  tier: string,
  userId: string,
  paymentMethodId: string,
  res: any
) {
  console.log(`🔄 [handleMobileSubscriptionFlow] Processing mobile subscription`);
  
  try {
    // Attach payment method to customer
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customer.id,
    });
    
    // Set as default payment method
    await stripe.customers.update(customer.id, {
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    });
    
    console.log(`✅ [handleMobileSubscriptionFlow] Payment method attached and set as default`);
  } catch (attachError) {
    console.error('❌ [handleMobileSubscriptionFlow] Failed to attach payment method:', attachError);
    res.status(400).json({success: false, error: 'Failed to attach payment method'});
    return;
  }

  // Create subscription with payment method
  const subscriptionParams = {
    customer: customer.id,
    items: [{price: priceId}],
    trial_period_days: 7,
    default_payment_method: paymentMethodId,
    metadata: {
      firebaseUID: userId,
      tier: tier,
      appName: "Theorie",
    },
  };
  
  try {
    const subscription = await stripe.subscriptions.create(subscriptionParams);

    console.log(`✅ [handleMobileSubscriptionFlow] Subscription created: ${subscription.id}`);
    console.log(`📋 [handleMobileSubscriptionFlow] Status: ${subscription.status}`);
    
    const response = {
      success: true,
      subscriptionId: subscription.id,
      customerId: customer.id,
      status: subscription.status,
      trialEnd: subscription.trial_end,
      message: 'Subscription created successfully with payment method',
    };

    res.json(response);
  } catch (subscriptionError: any) {
    console.error('❌ [handleMobileSubscriptionFlow] Subscription creation failed:', subscriptionError);
    res.status(500).json({success: false, error: `Failed to create subscription: ${subscriptionError.message || 'Unknown error'}`});
  }
}

/**
 * Handle web checkout flow with Stripe Checkout Session - UPDATED to use dynamic URLs
 */
async function handleWebCheckoutFlow(
  stripe: Stripe,
  customer: Stripe.Customer,
  priceId: string,
  tier: string,
  userId: string,
  email: string,
  res: any,
  successUrl?: string,
  cancelUrl?: string
) {
  console.log(`🔄 [handleWebCheckoutFlow] Creating Stripe Checkout Session`);
  
  // UPDATED: Use dynamic URLs or fallback to environment/default URLs
  const defaultSuccessUrl = `${process.env.WEBAPP_URL || 'http://localhost:3000'}`; ///subscription/success?session_id={CHECKOUT_SESSION_ID}`;
  const defaultCancelUrl = `${process.env.WEBAPP_URL || 'http://localhost:3000'}`;  ///subscription/cancel;
  
  const finalSuccessUrl = successUrl || defaultSuccessUrl;
  const finalCancelUrl = cancelUrl || defaultCancelUrl;
  
  console.log(`📋 [handleWebCheckoutFlow] Using URLs:`, {
    successUrl: finalSuccessUrl,
    cancelUrl: finalCancelUrl,
    providedByClient: {
      success: !!successUrl,
      cancel: !!cancelUrl
    }
  });
  
  try {
    // Create Stripe Checkout Session with dynamic URLs
    const session = await stripe.checkout.sessions.create({
      customer: customer.id,
      mode: 'subscription',
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      subscription_data: {
        trial_period_days: 7,
        metadata: {
          firebaseUID: userId,
          tier: tier,
          appName: "Theorie",
        },
      },
      // UPDATED: Use dynamic URLs from client or fallback
      success_url: finalSuccessUrl,
      cancel_url: finalCancelUrl,
      automatic_tax: { enabled: true },
      billing_address_collection: 'required',
      customer_update: {
        address: 'auto',
        name: 'auto',
      },
    });

    console.log(`✅ [handleWebCheckoutFlow] Checkout session created: ${session.id}`);
    console.log(`📋 [handleWebCheckoutFlow] Session URL: ${session.url}`);
    console.log(`📋 [handleWebCheckoutFlow] Session will redirect to: ${finalSuccessUrl} on success`);
    console.log(`📋 [handleWebCheckoutFlow] Session will redirect to: ${finalCancelUrl} on cancel`);
    
    const response = {
      success: true,
      sessionId: session.id,
      checkoutUrl: session.url,
      customerId: customer.id,
      message: 'Checkout session created successfully',
      // Include URLs in response for debugging
      redirectUrls: {
        success: finalSuccessUrl,
        cancel: finalCancelUrl
      }
    };

    res.json(response);
  } catch (checkoutError: any) {
    console.error('❌ [handleWebCheckoutFlow] Checkout session creation failed:', checkoutError);
    res.status(500).json({success: false, error: `Failed to create checkout session: ${checkoutError.message || 'Unknown error'}`});
  }
}

/**
 * FIXED: Timestamp conversion function to handle invalid values
 */
function buildSubscriptionData(subscription: Stripe.Subscription) {
  const hasAccess = ["active", "trialing"].includes(subscription.status);
  
  // FIXED: Safely convert timestamps, handling undefined/null values
  const safeTimestamp = (timestamp: number | null | undefined): admin.firestore.Timestamp | null => {
    if (!timestamp || typeof timestamp !== 'number' || timestamp <= 0) {
      return null;
    }
    try {
      return admin.firestore.Timestamp.fromDate(new Date(timestamp * 1000));
    } catch (error) {
      console.error('❌ Invalid timestamp conversion:', timestamp, error);
      return null;
    }
  };

  return {
    "id": subscription.id,
    "customerId": subscription.customer,
    "status": subscription.status,
    "tier": getSubscriptionTier(subscription),
    "currentPeriodStart": safeTimestamp((subscription as any).current_period_start),
    "currentPeriodEnd": safeTimestamp((subscription as any).current_period_end),
    "hasAccess": hasAccess,
    "cancelAtPeriodEnd": subscription.cancel_at_period_end || false,
    "trialEnd": safeTimestamp(subscription.trial_end),
    "needsPaymentUpdate": false,
    "statusDescription": getStatusDescription(subscription.status, subscription.cancel_at_period_end || false),
    "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  };
}

/**
 * Handle one-time payments - HTTPS
 */
export const createPaymentIntent = onRequest(
  {
    cors: false, // Handled manually
    invoker: "public",
    memory: "256MiB",
    timeoutSeconds: 30,
    secrets: [stripeSecretKey],
  },
  handleRequest(async (req, res, user) => {
    if (req.method !== 'POST') {
      res.status(405).json({success: false, error: 'Method not allowed'});
      return;
    }

    if (!user) {
      res.status(401).json({success: false, error: 'User must be authenticated'});
      return;
    }

    try {
      const stripe = getStripeInstance();
      const {amount, currency = "usd", description} = req.body;
      const userId = user.uid;

      console.log(`Creating payment intent for user ${userId}: $${amount}`);

      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100),
        currency: currency,
        description: description || "Theorie - One-time payment",
        metadata: {firebaseUID: userId, appName: "Theorie"},
        automatic_payment_methods: {enabled: true},
      });

      console.log(`Payment intent created: ${paymentIntent.id}`);

      res.json({
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      });
    } catch (error: any) {
      console.error("Error creating payment intent:", error);
      res.status(500).json({
        success: false,
        error: 'Unable to create payment intent',
        message: error.message
      });
    }
  })
);

/**
 * Cancel subscription - HTTPS
 */
export const cancelSubscription = onRequest(
  {
    cors: false, // Handled manually
    invoker: "public",
    memory: "256MiB",
    timeoutSeconds: 30,
    secrets: [stripeSecretKey],
  },
  handleRequest(async (req, res, user) => {
    if (req.method !== 'POST') {
      res.status(405).json({success: false, error: 'Method not allowed'});
      return;
    }

    if (!user) {
      res.status(401).json({success: false, error: 'User must be authenticated'});
      return;
    }

    try {
      const stripe = getStripeInstance();
      const {subscriptionId, cancelAtPeriodEnd = true} = req.body;
      const userId = user.uid;

      console.log(`Canceling subscription ${subscriptionId} for user ${userId}`);

      const subscription = await stripe.subscriptions.update(subscriptionId, {
        cancel_at_period_end: cancelAtPeriodEnd,
        metadata: {
          canceledBy: userId,
          canceledAt: new Date().toISOString(),
        },
      });

      console.log(`Subscription ${subscriptionId} cancel_at_period_end set to ${cancelAtPeriodEnd}`);

      res.json({success: true, subscription: subscription});
    } catch (error: any) {
      console.error("Error canceling subscription:", error);
      res.status(500).json({
        success: false,
        error: 'Unable to cancel subscription',
        message: error.message
      });
    }
  })
);

/**
 * Resume subscription - HTTPS
 */
export const resumeSubscription = onRequest(
  {
    cors: false, // Handled manually
    invoker: "public",
    memory: "256MiB",
    timeoutSeconds: 30,
    secrets: [stripeSecretKey],
  },
  handleRequest(async (req, res, user) => {
    if (req.method !== 'POST') {
      res.status(405).json({success: false, error: 'Method not allowed'});
      return;
    }

    if (!user) {
      res.status(401).json({success: false, error: 'User must be authenticated'});
      return;
    }

    try {
      const stripe = getStripeInstance();
      const {subscriptionId} = req.body;
      const userId = user.uid;

      console.log(`Resuming subscription ${subscriptionId} for user ${userId}`);

      const subscription = await stripe.subscriptions.update(subscriptionId, {
        cancel_at_period_end: false,
        metadata: {
          resumedBy: userId,
          resumedAt: new Date().toISOString(),
        },
      });

      console.log(`Subscription ${subscriptionId} resumed successfully`);

      res.json({success: true, subscription: subscription});
    } catch (error: any) {
      console.error("Error resuming subscription:", error);
      res.status(500).json({
        success: false,
        error: 'Unable to resume subscription',
        message: error.message
      });
    }
  })
);

/**
 * Stripe webhook handler - HTTPS
 */
export const stripeWebhook = onRequest(
  {
    cors: false,
    invoker: "public",
    memory: "512MiB",
    timeoutSeconds: 60,
    secrets: [stripeSecretKey, stripeWebhookSecret],
  },
  async (req, res) => {
    const stripe = getStripeInstance();
    const sig = req.headers["stripe-signature"] as string;
    const endpointSecret = stripeWebhookSecret.value();

    let event: Stripe.Event;

    try {
      // Fixed (uses raw body for proper signature verification)
      const body = req.rawBody || req.body;
      event = stripe.webhooks.constructEvent(body, sig, endpointSecret);
    } catch (err: any) {
      console.error("❌ Webhook signature verification failed:", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    console.log(`📧 Processing webhook event: ${event.type} (${event.id})`);

    try {
      switch (event.type) {
        case "customer.subscription.created":
          await handleSubscriptionCreated(event.data.object as Stripe.Subscription);
          break;
        case "customer.subscription.updated":
          await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
          break;
        case "customer.subscription.deleted":
          await handleSubscriptionCanceled(event.data.object as Stripe.Subscription);
          break;
        case "customer.subscription.trial_will_end":
          await handleTrialWillEnd(event.data.object as Stripe.Subscription);
          break;
        case "invoice.payment_succeeded":
          await handleInvoicePaymentSucceeded(event.data.object as Stripe.Invoice);
          break;
        case "invoice.payment_failed":
          await handleInvoicePaymentFailed(event.data.object as Stripe.Invoice);
          break;
        case "invoice.payment_action_required":
          await handlePaymentActionRequired(event.data.object as Stripe.Invoice);
          break;
        case "payment_intent.succeeded":
          await handleOneTimePaymentSucceeded(event.data.object as Stripe.PaymentIntent);
          break;
        case "payment_intent.payment_failed":
          await handlePaymentFailed(event.data.object as Stripe.PaymentIntent);
          break;
        case "customer.created":
          await handleCustomerCreated(event.data.object as Stripe.Customer);
          break;
        case "customer.updated":
          await handleCustomerUpdated(event.data.object as Stripe.Customer);
          break;
        case "setup_intent.succeeded":
          await handleSetupIntentSucceeded(event.data.object as Stripe.SetupIntent);
          break;
        default:
          console.log(`⚠️ Unhandled event type: ${event.type}`);
      }

      res.json({received: true, eventId: event.id});
    } catch (error: any) {
      console.error(`❌ Error processing webhook ${event.type}:`, error);
      res.status(500).json({
        error: "Webhook processing failed",
        eventType: event.type,
        message: error.message,
      });
    }
  }
);

// Helper functions (same as before but with better logging)
async function findUserByCustomerId(customerId: string) {
  try {
    const userQuery = await db.collection("users")
      .where("stripeCustomerId", "==", customerId)
      .limit(1)
      .get();
    return userQuery.empty ? null : userQuery.docs[0];
  } catch (error) {
    console.error("Error finding user by customer ID:", error);
    return null;
  }
}

async function findUserBySubscriptionId(subscriptionId: string) {
  try {
    const userQuery = await db.collection("users")
      .where("subscription.id", "==", subscriptionId)  
      .limit(1)
      .get();
    return userQuery.empty ? null : userQuery.docs[0];
  } catch (error) {
    console.error("Error finding user by subscription ID:", error);
    return null;
  }
}

function getSubscriptionTier(subscription: Stripe.Subscription): string {
  const priceId = subscription.items.data[0]?.price?.id;
  const tierMapping: {[key: string]: string} = {
    "price_1RsKbaILJ0OoLUiBITKrhYdn": "premium",
    "price_1RsKbbILJ0OoLUiBDlSe2quB": "premiumAnnual",
  };
  return tierMapping[priceId || ""] || "premium";
}

// function buildSubscriptionData(subscription: Stripe.Subscription) {
//   const hasAccess = ["active", "trialing"].includes(subscription.status);
//   return {
//     "id": subscription.id,
//     "customerId": subscription.customer,
//     "status": subscription.status,
//     "tier": getSubscriptionTier(subscription),
//     "currentPeriodStart": admin.firestore.Timestamp.fromDate(
//       new Date((subscription as any).current_period_start * 1000)
//     ),
//     "currentPeriodEnd": admin.firestore.Timestamp.fromDate(
//       new Date((subscription as any).current_period_end * 1000)
//     ),
//     "hasAccess": hasAccess,
//     "cancelAtPeriodEnd": subscription.cancel_at_period_end || false,
//     "trialEnd": subscription.trial_end ? admin.firestore.Timestamp.fromDate(
//       new Date(subscription.trial_end * 1000)
//     ) : null,
//     "needsPaymentUpdate": false,
//     "statusDescription": getStatusDescription(subscription.status, subscription.cancel_at_period_end || false),
//     "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
//   };
// }

function getStatusDescription(status: string, cancelAtPeriodEnd: boolean): string {
  if (cancelAtPeriodEnd && status === "active") return "Cancels at period end";
  const statusMap: {[key: string]: string} = {
    "active": "Active", "trialing": "Free trial", "past_due": "Payment overdue",
    "canceled": "Canceled", "unpaid": "Payment required", "incomplete": "Setup incomplete",
    "incomplete_expired": "Setup expired",
  };
  return statusMap[status] || status;
}

function getPriceId(tier: string): string {
  console.log(`🔍 Getting price ID for tier: "${tier}"`);
  
  // Use environment variables for price IDs with fallbacks
  const priceIds = {
    premium: process.env.STRIPE_PREMIUM_PRICE_ID || "price_1RsKbaILJ0OoLUiBITKrhYdn",
    premiumAnnual: process.env.STRIPE_PREMIUM_ANNUAL_PRICE_ID || "price_1RsKbbILJ0OoLUiBDlSe2quB",
  };
  
  console.log(`💰 Available tiers:`, Object.keys(priceIds));
  
  const priceId = priceIds[tier as keyof typeof priceIds];
  
  if (!priceId) {
    console.error(`❌ Invalid tier provided: "${tier}". Valid tiers are: ${Object.keys(priceIds).join(', ')}`);
    throw new Error(`Invalid subscription tier: ${tier}. Valid tiers are: ${Object.keys(priceIds).join(', ')}`);
  }
  
  console.log(`✅ Using price ID: ${priceId} for tier: ${tier}`);
  return priceId;
}

// Webhook handlers (same logic as before)
async function handleSubscriptionCreated(subscription: Stripe.Subscription) {
  console.log(`✅ Processing subscription.created: ${subscription.id}`);
  const userDoc = await findUserByCustomerId(subscription.customer as string);
  if (!userDoc) return;
  const subscriptionData = buildSubscriptionData(subscription);
  await userDoc.ref.update({
    "subscription": subscriptionData,
    "hasActiveSubscription": subscriptionData.hasAccess,
    "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✅ Subscription created for user: ${userDoc.id}`);
}

async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  console.log(`✅ Processing subscription.updated: ${subscription.id}`);
  const userDoc = await findUserBySubscriptionId(subscription.id);
  if (!userDoc) return;
  const subscriptionData = buildSubscriptionData(subscription);
  await userDoc.ref.update({
    "subscription": subscriptionData,
    "hasActiveSubscription": subscriptionData.hasAccess,
    "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✅ Subscription updated: ${subscription.id} - Status: ${subscription.status}`);
}

async function handleSubscriptionCanceled(subscription: Stripe.Subscription) {
  console.log(`✅ Processing subscription.deleted: ${subscription.id}`);
  const userDoc = await findUserBySubscriptionId(subscription.id);
  if (!userDoc) return;
  const subscriptionData = buildSubscriptionData(subscription);
  await userDoc.ref.update({
    "subscription": subscriptionData,
    "hasActiveSubscription": false,
    "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✅ Subscription canceled: ${subscription.id}`);
}

async function handleTrialWillEnd(subscription: Stripe.Subscription) {
  console.log(`⏰ Processing trial_will_end: ${subscription.id}`);
  const userDoc = await findUserBySubscriptionId(subscription.id);
  if (!userDoc) return;
  await userDoc.ref.update({
    "subscription.trialEnding": true,
    "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`⏰ Trial will end for subscription: ${subscription.id}`);
}

async function handleInvoicePaymentSucceeded(invoice: Stripe.Invoice) {
  if (!(invoice as any).subscription) return;
  console.log(`✅ Processing invoice.payment_succeeded: ${invoice.id}`);
  const userDoc = await findUserBySubscriptionId((invoice as any).subscription as string);
  if (!userDoc) return;
  await userDoc.ref.update({
    "subscription.status": "active",
    "subscription.hasAccess": true,
    "subscription.needsPaymentUpdate": false,
    "subscription.lastPaymentDate": admin.firestore.Timestamp.fromDate(new Date(invoice.created * 1000)),
    "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
    "hasActiveSubscription": true,
  });
  await db.collection("payments").add({
    userId: userDoc.id, invoiceId: invoice.id, subscriptionId: (invoice as any).subscription,
    amount: invoice.amount_paid, currency: invoice.currency, status: "succeeded",
    paidAt: admin.firestore.Timestamp.fromDate(new Date(invoice.created * 1000)),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✅ Payment succeeded for subscription: ${(invoice as any).subscription}`);
}

async function handleInvoicePaymentFailed(invoice: Stripe.Invoice) {
  if (!(invoice as any).subscription) return;
  console.log(`❌ Processing invoice.payment_failed: ${invoice.id}`);
  const userDoc = await findUserBySubscriptionId((invoice as any).subscription as string);
  if (!userDoc) return;
  await userDoc.ref.update({
    "subscription.status": "past_due", "subscription.hasAccess": false,
    "subscription.needsPaymentUpdate": true,
    "subscription.statusDescription": "Payment failed - update payment method",
    "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
    "hasActiveSubscription": false,
  });
  await db.collection("payments").add({
    userId: userDoc.id, invoiceId: invoice.id, subscriptionId: (invoice as any).subscription,
    amount: invoice.amount_due, currency: invoice.currency, status: "failed",
    failureReason: "payment_failed", createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`❌ Payment failed for subscription: ${(invoice as any).subscription}`);
}

async function handlePaymentActionRequired(invoice: Stripe.Invoice) {
  if (!(invoice as any).subscription) return;
  console.log(`🔐 Processing invoice.payment_action_required: ${invoice.id}`);
  const userDoc = await findUserBySubscriptionId((invoice as any).subscription as string);
  if (!userDoc) return;
  await userDoc.ref.update({
    "subscription.needsPaymentUpdate": true,
    "subscription.statusDescription": "Payment authentication required",
    "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`🔐 Payment action required for subscription: ${(invoice as any).subscription}`);
}

async function handleOneTimePaymentSucceeded(paymentIntent: Stripe.PaymentIntent) {
  if (!paymentIntent.customer) return;
  console.log(`✅ Processing payment_intent.succeeded: ${paymentIntent.id}`);
  const userDoc = await findUserByCustomerId(paymentIntent.customer as string);
  if (!userDoc) return;
  await db.collection("payments").add({
    userId: userDoc.id, paymentIntentId: paymentIntent.id, type: "one_time",
    amount: paymentIntent.amount, currency: paymentIntent.currency, status: "succeeded",
    metadata: paymentIntent.metadata || {},
    paidAt: admin.firestore.Timestamp.fromDate(new Date(paymentIntent.created * 1000)),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✅ One-time payment succeeded: ${paymentIntent.id}`);
}

async function handlePaymentFailed(paymentIntent: Stripe.PaymentIntent) {
  console.log(`❌ Processing payment_intent.payment_failed: ${paymentIntent.id}`);
  if (paymentIntent.customer) {
    const userDoc = await findUserByCustomerId(paymentIntent.customer as string);
    if (userDoc) {
      await db.collection("payments").add({
        userId: userDoc.id, paymentIntentId: paymentIntent.id, type: "one_time",
        amount: paymentIntent.amount, currency: paymentIntent.currency, status: "failed",
        failureReason: paymentIntent.last_payment_error?.message || "Payment failed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
}

async function handleCustomerCreated(customer: Stripe.Customer) {
  console.log(`✅ Processing customer.created: ${customer.id}`);
}

async function handleCustomerUpdated(customer: Stripe.Customer) {
  console.log(`✅ Processing customer.updated: ${customer.id}`);
  if (customer.metadata?.firebaseUID) {
    const userId = customer.metadata.firebaseUID;
    await db.collection("users").doc(userId).update({
      stripeCustomerEmail: customer.email, stripeCustomerName: customer.name,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`✅ Customer updated: ${customer.id}`);
  }
}

async function handleSetupIntentSucceeded(setupIntent: Stripe.SetupIntent) {
  if (!setupIntent.customer) return;
  console.log(`✅ Processing setup_intent.succeeded: ${setupIntent.id}`);
  const userDoc = await findUserByCustomerId(setupIntent.customer as string);
  if (!userDoc) return;
  await userDoc.ref.update({
    "subscription.needsPaymentUpdate": false,
    "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✅ Setup intent succeeded for customer: ${setupIntent.customer}`);
}