// functions/src/types/stripe.d.ts
// This file extends Stripe TypeScript definitions to support newer API versions

declare module 'stripe' {
  namespace Stripe {
    interface StripeConfig {
      apiVersion?: 
        | '2023-10-16'
        | '2024-06-20'
        | '2024-09-30.acacia'
        | '2024-11-20.acacia'
        | '2025-01-27.acacia'
        | '2025-07-30.basil'
        | string; // Allow any string as fallback
    }
  }
}