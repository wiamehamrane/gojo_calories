export interface Influencer {
  id: string;
  user_id: string;
  email: string | null;
  name: string | null;
  display_name: string;
  handle: string | null;
  platform: string | null;
  notes: string | null;
  commission_rate: number | null;
  panel_access: boolean;
  is_active: boolean;
  has_paid: boolean;
  subscription_source: string | null;
  subscription_expires_at: string | null;
  total_codes: number;
  active_codes: number;
  total_redemptions: number;
  created_at: string | null;
}

export type PromoPlatform = "internal" | "apple" | "google";

export interface PromoCode {
  id: string;
  code: string;
  platform: PromoPlatform;
  plan_type: string;
  store_product_id: string | null;
  notes: string | null;
  max_redemptions: number | null;
  redemption_count: number;
  is_active: boolean;
  expires_at: string | null;
  created_at: string | null;
  remaining: number | null;
  redeem_url: string | null;
}

export interface PromoRedemption {
  id: string;
  user_email: string | null;
  code: string | null;
  plan_granted: string;
  redeemed_at: string | null;
}

export interface InfluencerDetail extends Influencer {
  promo_codes: PromoCode[];
  recent_redemptions: PromoRedemption[];
}
