"use client";

import { useState } from "react";
import { Button } from "@/components/ui";
import type { UserDetail } from "@/lib/types";

export interface UserFormData {
  email: string;
  password: string;
  name: string;
  is_email_verified: boolean;
  has_paid: boolean;
  is_admin: boolean;
  is_banned: boolean;
  subscription_source: string;
  current_weight: string;
  goal_weight: string;
  weight_unit: string;
  age: string;
  gender: string;
  activity_level: string;
  phone: string;
}

export const emptyUserForm = (): UserFormData => ({
  email: "",
  password: "",
  name: "",
  is_email_verified: false,
  has_paid: false,
  is_admin: false,
  is_banned: false,
  subscription_source: "",
  current_weight: "",
  goal_weight: "",
  weight_unit: "kg",
  age: "",
  gender: "",
  activity_level: "sedentary",
  phone: "",
});

export function userToFormData(user: UserDetail): UserFormData {
  return {
    email: user.email || "",
    password: "",
    name: user.name || "",
    is_email_verified: user.is_email_verified,
    has_paid: user.has_paid,
    is_admin: user.is_admin,
    is_banned: user.is_banned,
    subscription_source: user.subscription_source || "",
    current_weight: user.current_weight != null ? String(user.current_weight) : "",
    goal_weight: user.goal_weight != null ? String(user.goal_weight) : "",
    weight_unit: user.weight_unit || "kg",
    age: user.age != null ? String(user.age) : "",
    gender: user.gender || "",
    activity_level: user.activity_level || "sedentary",
    phone: user.phone || "",
  };
}

export function formDataToPayload(data: UserFormData, mode: "create" | "edit") {
  const payload: Record<string, unknown> = {
    email: data.email.trim(),
    name: data.name.trim() || null,
    is_email_verified: data.is_email_verified,
    has_paid: data.has_paid,
    is_admin: data.is_admin,
    is_banned: data.is_banned,
    subscription_source: data.subscription_source || null,
    weight_unit: data.weight_unit || "kg",
    gender: data.gender || null,
    activity_level: data.activity_level || null,
    phone: data.phone.trim() || null,
  };

  if (data.password.trim()) {
    payload.password = data.password;
  } else if (mode === "create") {
    payload.password = data.password;
  }

  if (data.current_weight) payload.current_weight = parseFloat(data.current_weight);
  if (data.goal_weight) payload.goal_weight = parseFloat(data.goal_weight);
  if (data.age) payload.age = parseInt(data.age, 10);

  return payload;
}

const inputClass =
  "w-full rounded-2xl border border-border bg-background px-4 py-2.5 text-sm outline-none focus:border-primary";

interface UserFormProps {
  data: UserFormData;
  onChange: (data: UserFormData) => void;
  mode: "create" | "edit";
}

export function UserForm({ data, onChange, mode }: UserFormProps) {
  function set<K extends keyof UserFormData>(key: K, value: UserFormData[K]) {
    onChange({ ...data, [key]: value });
  }

  return (
    <div className="grid gap-4 md:grid-cols-2">
      <Field label="Email" required>
        <input
          type="email"
          required
          value={data.email}
          onChange={(e) => set("email", e.target.value)}
          className={inputClass}
        />
      </Field>

      <Field
        label={mode === "create" ? "Password" : "New password"}
        required={mode === "create"}
      >
        <input
          type="password"
          required={mode === "create"}
          value={data.password}
          onChange={(e) => set("password", e.target.value)}
          placeholder={mode === "edit" ? "Leave blank to keep current" : ""}
          className={inputClass}
        />
      </Field>

      <Field label="Name">
        <input
          type="text"
          value={data.name}
          onChange={(e) => set("name", e.target.value)}
          className={inputClass}
        />
      </Field>

      <Field label="Phone">
        <input
          type="text"
          value={data.phone}
          onChange={(e) => set("phone", e.target.value)}
          className={inputClass}
        />
      </Field>

      <Field label="Current weight">
        <input
          type="number"
          step="0.1"
          value={data.current_weight}
          onChange={(e) => set("current_weight", e.target.value)}
          className={inputClass}
        />
      </Field>

      <Field label="Goal weight">
        <input
          type="number"
          step="0.1"
          value={data.goal_weight}
          onChange={(e) => set("goal_weight", e.target.value)}
          className={inputClass}
        />
      </Field>

      <Field label="Weight unit">
        <select
          value={data.weight_unit}
          onChange={(e) => set("weight_unit", e.target.value)}
          className={inputClass}
        >
          <option value="kg">kg</option>
          <option value="lb">lb</option>
        </select>
      </Field>

      <Field label="Age">
        <input
          type="number"
          value={data.age}
          onChange={(e) => set("age", e.target.value)}
          className={inputClass}
        />
      </Field>

      <Field label="Gender">
        <select
          value={data.gender}
          onChange={(e) => set("gender", e.target.value)}
          className={inputClass}
        >
          <option value="">—</option>
          <option value="male">Male</option>
          <option value="female">Female</option>
        </select>
      </Field>

      <Field label="Activity level">
        <select
          value={data.activity_level}
          onChange={(e) => set("activity_level", e.target.value)}
          className={inputClass}
        >
          <option value="sedentary">Sedentary</option>
          <option value="light">Light</option>
          <option value="moderate">Moderate</option>
          <option value="active">Active</option>
          <option value="very_active">Very active</option>
        </select>
      </Field>

      <Field label="Subscription source">
        <select
          value={data.subscription_source}
          onChange={(e) => set("subscription_source", e.target.value)}
          className={inputClass}
        >
          <option value="">None</option>
          <option value="apple">Apple</option>
          <option value="google">Google</option>
          <option value="stripe">Stripe</option>
        </select>
      </Field>

      <div className="md:col-span-2 flex flex-wrap gap-4 pt-2">
        <Checkbox
          label="Email verified"
          checked={data.is_email_verified}
          onChange={(v) => set("is_email_verified", v)}
        />
        <Checkbox
          label="Pro subscriber"
          checked={data.has_paid}
          onChange={(v) => set("has_paid", v)}
        />
        <Checkbox
          label="Admin"
          checked={data.is_admin}
          onChange={(v) => set("is_admin", v)}
        />
        <Checkbox
          label="Banned"
          checked={data.is_banned}
          onChange={(v) => set("is_banned", v)}
        />
      </div>
    </div>
  );
}

function Field({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-sm font-medium text-text-primary">
        {label}
        {required && <span className="text-danger"> *</span>}
      </span>
      {children}
    </label>
  );
}

function Checkbox({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label className="flex cursor-pointer items-center gap-2 text-sm text-text-primary">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="h-4 w-4 rounded border-border accent-primary-dark"
      />
      {label}
    </label>
  );
}

interface ModalProps {
  title: string;
  open: boolean;
  onClose: () => void;
  children: React.ReactNode;
  footer?: React.ReactNode;
}

export function Modal({ title, open, onClose, children, footer }: ModalProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-[20px] border border-border bg-surface p-6 shadow-lg">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-xl font-bold text-text-primary">{title}</h2>
          <button
            onClick={onClose}
            className="text-text-secondary hover:text-text-primary"
          >
            ✕
          </button>
        </div>
        {children}
        {footer && <div className="mt-6 flex justify-end gap-2">{footer}</div>}
      </div>
    </div>
  );
}

export function UserFormActions({
  onCancel,
  onSubmit,
  loading,
  submitLabel,
}: {
  onCancel: () => void;
  onSubmit: () => void;
  loading?: boolean;
  submitLabel: string;
}) {
  return (
    <>
      <Button variant="secondary" onClick={onCancel} disabled={loading}>
        Cancel
      </Button>
      <Button type="button" onClick={onSubmit} disabled={loading}>
        {loading ? "Saving..." : submitLabel}
      </Button>
    </>
  );
}
