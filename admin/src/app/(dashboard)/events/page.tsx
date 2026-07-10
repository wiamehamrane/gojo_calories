"use client";

import { useState } from "react";
import { usePaginatedData } from "@/hooks/usePaginatedData";
import type { EventItem } from "@/lib/types";
import { apiFetch } from "@/lib/api";
import {
  Badge,
  Button,
  DataTable,
  PageHeader,
  Pagination,
  SearchInput,
} from "@/components/ui";

export default function EventsPage() {
  const [search, setSearch] = useState("");
  const { data, page, setPage, loading, refresh } =
    usePaginatedData<EventItem>("/admin/events", { search });

  async function remove(id: string) {
    if (!confirm("Delete this event?")) return;
    await apiFetch(`/admin/events/${id}`, { method: "DELETE" });
    refresh();
  }

  return (
    <div>
      <PageHeader title="Events" description="Manage community fitness events" />
      <div className="mb-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search events..." />
      </div>

      {loading ? (
        <div className="flex h-40 items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      ) : (
        <>
          <DataTable
            columns={[
              { key: "title", label: "Title" },
              { key: "type", label: "Type" },
              { key: "location", label: "Location" },
              { key: "participants", label: "Participants" },
              { key: "date", label: "Date" },
              { key: "actions", label: "", className: "text-right" },
            ]}
            rows={(data?.items || []).map((e) => ({
              title: e.title,
              type: <Badge>{e.event_type}</Badge>,
              location: e.location_name || "—",
              participants: `${e.participant_count}${e.max_participants ? `/${e.max_participants}` : ""}`,
              date: e.start_time
                ? new Date(e.start_time).toLocaleDateString()
                : "—",
              actions: (
                <Button variant="danger" onClick={() => remove(e.id)}>
                  Delete
                </Button>
              ),
            }))}
          />
          {data && (
            <Pagination page={page} totalPages={data.total_pages} onPageChange={setPage} />
          )}
        </>
      )}
    </div>
  );
}
