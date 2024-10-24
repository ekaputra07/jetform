defmodule AppWeb.AdminLive.Product.Edit do
  use AppWeb, :live_view
  alias App.Products
  alias AppWeb.AdminLive.Product.Components.{EditForm, Preview}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    product = Products.get_product!(id) |> App.Repo.preload(:user)

    # data for thanks page preview
    dummy_order = %App.Orders.Order{
      id: Pow.UUID.generate(),
      customer_name: "John Doe",
      customer_email: "john@example.com",
      customer_phone: "08123456789",
      status: :free,
      invoice_number: "INV-123"
    }

    thanks_config = Products.ThanksPageConfig.get_or_default(product)
    brand_info = App.Users.get_brand_info(product.user)

    socket =
      socket
      |> assign(:page_title, "Edit: #{product.name}")
      |> assign(:product, product)
      |> assign(:changeset, Products.change_product(product, %{}))
      |> assign(:dummy_order, dummy_order)
      |> assign(:thanks_config, thanks_config)
      |> assign(:brand_info, brand_info)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Products.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    socket =
      case Products.update_product(socket.assigns.product, product_params) do
        {:ok, product} ->
          socket
          |> assign(:product, product)
          |> assign(:changeset, Products.change_product(product, %{}))
          |> put_flash(:info, "Produk berhasil disimpan.")
          |> redirect(to: ~p"/products/#{product.id}/stats")

        {:error, changeset} ->
          socket
          |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_attribute", _params, socket) do
    socket =
      update(socket, :changeset, fn changeset ->
        attributes = Ecto.Changeset.get_field(changeset, :attributes, [])
        Ecto.Changeset.put_embed(changeset, :attributes, attributes ++ [%{}])
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_attribute", %{"index" => index}, socket) do
    index = String.to_integer(index)

    socket =
      update(socket, :changeset, fn changeset ->
        attributes = Ecto.Changeset.get_field(changeset, :attributes, [])
        Ecto.Changeset.put_embed(changeset, :attributes, List.delete_at(attributes, index))
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) do
    {:noreply, assign(socket, :tab, tab)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :tab, "details")}
  end

  # handle messages from child components
  @impl true
  def handle_info({:flash, :clear}, socket) do
    {:noreply, clear_flash(socket)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def handle_info(:images_updated, socket) do
    {:noreply, update_preview(socket)}
  end

  @impl true
  def handle_info(:variants_updated, socket) do
    {:noreply, update_preview(socket)}
  end

  @impl true
  def handle_info({:thanks_config_updated, config}, socket) do
    {:noreply, assign(socket, :thanks_config, config)}
  end

  defp update_preview(socket) do
    product = socket.assigns.product
    send_update(Preview, id: product.id, product: product)
    socket
  end
end
