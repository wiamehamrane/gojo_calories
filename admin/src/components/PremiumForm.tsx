import { ChevronLeft } from "lucide-react";
import Link from "next/link";

export function PremiumPageHero({
  backHref,
  backLabel,
  title,
  description,
}: {
  backHref: string;
  backLabel: string;
  title: string;
  description: string;
}) {
  return (
    <div className="mb-8">
      <Link
        href={backHref}
        className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-text-secondary transition-colors hover:text-primary-dark"
      >
        <ChevronLeft size={16} />
        {backLabel}
      </Link>
      <h1 className="text-3xl font-bold tracking-tight text-text-primary">
        {title}
      </h1>
      <p className="mt-2 max-w-2xl text-[15px] leading-relaxed text-text-secondary">
        {description}
      </p>
    </div>
  );
}

export function FormSection({
  title,
  description,
  children,
}: {
  title: string;
  description?: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-[24px] border border-border/80 bg-surface p-6 shadow-[0_1px_2px_rgba(0,0,0,0.04),0_12px_32px_rgba(0,125,143,0.05)]">
      <div className="mb-5 border-b border-border/60 pb-4">
        <h2 className="text-[15px] font-semibold text-text-primary">{title}</h2>
        {description && (
          <p className="mt-1 text-sm text-text-secondary">{description}</p>
        )}
      </div>
      {children}
    </section>
  );
}

export function FormField({
  label,
  required,
  hint,
  children,
  className = "",
}: {
  label: string;
  required?: boolean;
  hint?: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <label className={`block ${className}`}>
      <span className="mb-2 block text-[13px] font-medium text-text-primary">
        {label}
        {required && <span className="text-primary-dark"> *</span>}
      </span>
      {children}
      {hint && (
        <span className="mt-1.5 block text-xs text-text-secondary">{hint}</span>
      )}
    </label>
  );
}

export const premiumInputClass =
  "w-full rounded-2xl border border-border/80 bg-[#FAFAFA] px-4 py-3 text-sm text-text-primary outline-none transition-all placeholder:text-text-placeholder focus:border-primary focus:bg-white focus:shadow-[0_0_0_3px_rgba(0,180,204,0.12)]";

export function ToggleSwitch({
  checked,
  onChange,
  label,
  description,
}: {
  checked: boolean;
  onChange: (v: boolean) => void;
  label: string;
  description?: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className="flex w-full items-center justify-between gap-4 rounded-2xl border border-border/80 bg-[#FAFAFA] px-4 py-3.5 text-left transition-colors hover:bg-white"
    >
      <div>
        <p className="text-sm font-medium text-text-primary">{label}</p>
        {description && (
          <p className="mt-0.5 text-xs text-text-secondary">{description}</p>
        )}
      </div>
      <div
        className={`relative h-7 w-12 shrink-0 rounded-full transition-colors ${
          checked ? "bg-primary-dark" : "bg-border"
        }`}
      >
        <div
          className={`absolute top-0.5 h-6 w-6 rounded-full bg-white shadow-sm transition-transform ${
            checked ? "translate-x-[22px]" : "translate-x-0.5"
          }`}
        />
      </div>
    </button>
  );
}

export function PlanOption({
  label,
  description,
  selected,
  onSelect,
}: {
  label: string;
  description: string;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      className={`rounded-2xl border px-4 py-3 text-left transition-all ${
        selected
          ? "border-primary-dark bg-surface-teal-light shadow-[0_0_0_1px_#007D8F]"
          : "border-border/80 bg-[#FAFAFA] hover:border-primary/40 hover:bg-white"
      }`}
    >
      <p
        className={`text-sm font-semibold ${
          selected ? "text-primary-dark" : "text-text-primary"
        }`}
      >
        {label}
      </p>
      <p className="mt-0.5 text-xs text-text-secondary">{description}</p>
    </button>
  );
}

export function PlatformChip({
  label,
  selected,
  onSelect,
}: {
  label: string;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      className={`rounded-full px-4 py-2 text-sm font-medium capitalize transition-all ${
        selected
          ? "bg-primary-dark text-white shadow-sm"
          : "border border-border/80 bg-[#FAFAFA] text-text-secondary hover:border-primary/30 hover:text-text-primary"
      }`}
    >
      {label}
    </button>
  );
}
