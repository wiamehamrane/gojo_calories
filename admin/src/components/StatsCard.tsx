import { LucideIcon } from "lucide-react";

interface StatsCardProps {
  label: string;
  value: number | string;
  icon: LucideIcon;
  accent?: string;
}

export function StatsCard({ label, value, icon: Icon, accent }: StatsCardProps) {
  return (
    <div className="rounded-[20px] border border-border bg-surface p-5 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-text-secondary">{label}</p>
          <p className="mt-2 text-3xl font-bold text-text-primary">{value}</p>
        </div>
        <div
          className="flex h-11 w-11 items-center justify-center rounded-2xl"
          style={{ backgroundColor: accent || "#E0F8FB", color: "#007D8F" }}
        >
          <Icon size={20} />
        </div>
      </div>
    </div>
  );
}
