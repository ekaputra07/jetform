defmodule App.Plans.Commission5 do
  @behaviour App.Plans.Plan

  @id "plan-comm-5"
  @name "Snappy 5"
  @description "Snappy fee 5% per transaksi (dengan minimum Rp. 5,000 per transaksi)"
  @commission_percent 5
  @min_commission_value 5_000

  def id(), do: @id
  def name(), do: @name
  def description(), do: @description
  def valid_until(_now), do: ~U[9999-12-31 23:59:59Z]

  def commission(value) do
    cond do
      value == 0 -> 0
      true -> max(trunc(value * @commission_percent / 100), @min_commission_value)
    end
  end
end