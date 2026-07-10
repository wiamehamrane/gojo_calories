"use client";

import { useCallback, useEffect, useState } from "react";
import { apiFetch } from "@/lib/api";
import type { PaginatedResponse } from "@/lib/types";

export function usePaginatedData<T>(
  endpoint: string,
  params: Record<string, string | number | boolean | undefined> = {}
) {
  const [data, setData] = useState<PaginatedResponse<T> | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    setLoading(true);
    const query = new URLSearchParams();
    query.set("page", String(page));
    query.set("page_size", "20");
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== "") {
        query.set(key, String(value));
      }
    }
    try {
      const result = await apiFetch<PaginatedResponse<T>>(
        `${endpoint}?${query.toString()}`
      );
      setData(result);
    } finally {
      setLoading(false);
    }
  }, [endpoint, page, JSON.stringify(params)]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, page, setPage, loading, refresh: fetchData };
}
