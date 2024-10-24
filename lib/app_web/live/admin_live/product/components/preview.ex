defmodule AppWeb.AdminLive.Product.Components.Checkout do
  defstruct [:product, :variant, :price_type, :price, discount_value: 0, unique_code: 0]

  @types %{
    price: :integer,
    discount_value: :integer,
    unique_code: :integer
  }

  def changeset(checkout, attrs) do
    {checkout, @types}
    |> Ecto.Changeset.cast(attrs, Map.keys(@types))
  end

  def full_name(checkout) do
    if checkout.variant do
      "#{checkout.product.name} - #{checkout.variant.name}"
    else
      checkout.product.name
    end
  end

  def total(checkout) do
    checkout.price + checkout.unique_code - checkout.discount_value
  end
end

defmodule AppWeb.AdminLive.Product.Components.Preview do
  use AppWeb, :live_component
  use AppWeb, :html

  require Integer
  alias App.{Products, Orders}
  alias App.Orders.Order
  alias App.Captcha
  alias AppWeb.AdminLive.Product.Components.Checkout

  @impl true
  def render(assigns) do
    assigns =
      cond do
        !assigns.preview and assigns.product.is_live -> Map.put(assigns, :tracking, "true")
        true -> Map.put(assigns, :tracking, "false")
      end

    ~H"""
    <%!-- preview --%>
    <div
      class="p-1 md:p-6"
      id={"product-" <> @product.id}
      phx-hook="UmamiView"
      data-if={@tracking}
      data-url={App.Umami.URL.for(@product)}
    >
      <.product_detail
        :if={@step == "details"}
        product={@product}
        images={@images}
        changeset={@checkout_changeset}
        product_variants={@product_variants}
        has_variants={@has_variants}
        selected_variant_id={@selected_variant_id}
        submit_event="checkout"
        submit_target={@myself}
        tracking={@tracking}
      />

      <.checkout_form
        :if={@step == "checkout"}
        product={@product}
        changeset={@order_changeset}
        checkout={@checkout}
        payment_channels={@payment_channels}
        selected_payment_channel={@selected_payment_channel}
        change_event="validate_order"
        submit_event={if @preview, do: "simulate_order", else: "create_order"}
        submit_target={@myself}
        enable_captcha={@enable_captcha}
        tracking={@tracking}
      />

      <p class="text-center pt-4">
        <.link
          navigate={AppWeb.Utils.marketing_site()}
          target="_blank"
          class="mx-auto justify-center items-start text-xs font-normal text-slate-400/50 rounded-md border border-slate-400/50 p-1 px-2"
        >
          Powered by JetForm
        </.link>
      </p>
    </div>
    <%!-- end preview --%>
    """
  end

  attr :product, :map, required: true
  attr :images, :list, required: true
  attr :changeset, :map, required: true
  attr :submit_event, :string, required: true
  attr :submit_target, :any, required: true
  attr :product_variants, :list, default: []
  attr :has_variants, :boolean, default: false
  attr :selected_variant_id, :string, default: nil
  attr :tracking, :string, required: true

  def product_detail(assigns) do
    ~H"""
    <div class="mx-auto max-w-lg rounded-md bg-white shadow-lg overflow-hidden border">
      <%= if not Enum.empty?(@images) do %>
        <div id={"glide-" <> @product.id} class="glide" phx-hook="InitGlide">
          <div class="glide__track" data-glide-el="track">
            <ul class="glide__slides">
              <li :for={image <- @images} class="glide__slide">
                <img src={Products.image_url(image, :standard)} />
              </li>
            </ul>
          </div>
          <div :if={length(@images) > 1} class="glide__arrows" data-glide-el="controls">
            <button
              class="transition-colors bg-white hover:bg-gray-50 px-1 rounded h-8 w-8 text-black absolute top-0 bottom-0 -left-1 mt-auto mb-auto shadow-md focus:outline-none"
              data-glide-dir="<"
            >
              <.icon name="hero-chevron-left" class="h-6 w-6 text-slate-500" />
            </button>
            <button
              class="transition-colors bg-white hover:bg-gray-50 px-1 rounded h-8 w-8 text-black absolute top-0 bottom-0 -right-1 mt-auto mb-auto shadow-md focus:outline-none"
              data-glide-dir=">"
            >
              <.icon name="hero-chevron-right" class="h-6 w-6 text-slate-500" />
            </button>
          </div>
        </div>
      <% end %>
      <hr />
      <div class="p-6 space-y-5">
        <%!-- title and desc --%>
        <h2 class="text-2xl font-semibold" id="preview" phx-update="replace">
          <%= @product.name %>
        </h2>

        <div class="mt-4 trix-content preview text-gray-600">
          <%= raw(@product.description) %>
        </div>

        <%!-- attrbutes table --%>
        <div :if={Products.has_attributes?(@product)} class="relative overflow-x-auto rounded-md">
          <table class="w-full text-sm text-left rtl:text-right text-gray-700 dark:text-gray-700">
            <tbody>
              <tr
                :for={{item, index} <- Enum.with_index(@product.attributes)}
                class={if Integer.is_even(index), do: "bg-primary-100", else: "bg-primary-50"}
              >
                <td
                  scope="row"
                  class="p-2 font-medium text-gray-700 whitespace-nowrap dark:text-gray-700"
                >
                  <%= item.key %>
                </td>
                <td
                  scope="row"
                  class="p-2 font-medium text-gray-700 whitespace-nowrap dark:text-gray-700"
                >
                  <.icon name="hero-chevron-right me-2 w-3 h-3" /> <%= item.value %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <.simple_form
          :let={f}
          for={@changeset}
          as={:checkout}
          phx-update="replace"
          phx-submit={@submit_event}
          phx-target={@submit_target}
        >
          <%!-- variant choices --%>
          <div :if={@has_variants} class="grid gap-2">
            <input type="hidden" name="checkout[variant_id]" value={@selected_variant_id} />
            <div :for={variant <- @product_variants} class="relative shadow">
              <input
                class="peer hidden"
                id={"radio_" <> variant.id}
                type="radio"
                name="variant"
                phx-click={
                  JS.push("select_variant",
                    value: %{"id" => variant.id},
                    target: @submit_target,
                    page_loading: true
                  )
                }
                checked={variant.id == @selected_variant_id}
              />
              <span class="peer-checked:border-primary-700 absolute right-4 top-7 box-content block h-3 w-3 -translate-y-1/2 rounded-full border-8 border-gray-300 bg-white">
              </span>
              <label
                class="peer-checked:border-2 peer-checked:border-primary-700 peer-checked:bg-primary-50 flex cursor-pointer select-none rounded-md border border-gray-300 p-4"
                for={"radio_" <> variant.id}
              >
                <div class="w-full">
                  <div class="font-semibold flex pr-12">
                    <span class="flex-1 text-primary-600 font-bold"><%= variant.name %></span>
                    <.price value={variant.price} />
                  </div>
                  <p class="text-slate-600 text-sm mt-1 pr-10">
                    <%= variant.description %>
                  </p>
                </div>
              </label>
            </div>
          </div>

          <%!-- fixed price --%>
          <p
            :if={!@has_variants && @product.price_type == :fixed}
            class="bg-slate-50 text-lg font-semibold text-slate-900 py-2 px-6 rounded-md shadow-md border text-center"
          >
            <%!-- <span class="line-through font-normal text-xs text-red-500 block">Rp. 150,000</span> --%>
            <.price value={@product.price} />
          </p>

          <%!-- pay what you want --%>
          <div
            :if={!@has_variants && @product.price_type == :flexible}
            class="md:flex items-center justify-between pt-3 p-4 bg-slate-50 rounded-md shadow-md border"
          >
            <div class="text-lg font-medium text-gray-900">
              Pay what you want
              <div class="text-xs text-gray-400">Minimal <.price value={@product.price} /></div>
            </div>
            <.input type="number" field={f[:price]} required />
          </div>

          <:actions>
            <div class="">
              <button
                id="cta-submit"
                phx-hook="UmamiClick"
                data-if={@tracking}
                data-event="cta-submit"
                data-url={App.Umami.URL.for(@product)}
                type="submit"
                class="mt-5 w-full items-center justify-center rounded-md bg-primary-600 p-4 text-lg font-semibold text-white transition-all duration-200 ease-in-out focus:shadow hover:bg-primary-700"
              >
                <%= @product.cta %>
              </button>
            </div>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  attr :product, :map, required: true
  attr :changeset, :map, required: true
  attr :checkout, :map, required: true
  attr :change_event, :string, required: true
  attr :submit_event, :string, required: true
  attr :submit_target, :any, required: true
  attr :payment_channels, :map, required: true
  attr :selected_payment_channel, :string, default: nil
  attr :enable_captcha, :boolean, default: true
  attr :tracking, :string, required: true

  def checkout_form(assigns) do
    checkout = assigns.checkout
    total_price = Checkout.total(checkout)

    allow_submit =
      checkout.price_type == :free or
        (total_price > 0 and not is_nil(assigns.selected_payment_channel))

    assigns =
      assigns
      |> Map.put(:total_price, total_price)
      |> Map.put(:allow_submit, allow_submit)

    ~H"""
    <div class="mx-auto max-w-lg rounded-md bg-white shadow-lg border overflow-hidden">
      <%!--  FORM --%>
      <div class="space-y-4">
        <.simple_form
          :let={f}
          for={@changeset}
          as={:order}
          phx-update="replace"
          phx-change={@change_event}
          phx-submit={@submit_event}
          phx-target={@submit_target}
        >
          <p class="p-3 text-sm text-white bg-primary-600">
            <.link
              href="#"
              phx-click={
                JS.push("step", value: %{step: "details"}, target: @submit_target, page_loading: true)
              }
            >
              <.icon name="hero-arrow-long-left" /> Detail produk
            </.link>
          </p>
          <p :if={@total_price > 0} class="py-3 px-6 text-sm font-semibold bg-slate-100 border-b">
            Data pembeli
          </p>
          <div class="space-y-2 p-6 bg-white" id="customer-info-fields" phx-update="ignore">
            <.input field={f[:customer_name]} type="text" label="Nama *" required />
            <.input
              field={f[:customer_email]}
              type="email"
              label="Alamat email *"
              required
              wrapper_class="flex-1"
            />
            <.input
              field={f[:customer_phone]}
              type="text"
              label="No. HP / WhatsApp"
              wrapper_class="flex-1 mt-4 md:mt-0"
            />
            <div :if={@enable_captcha} id="cf-turnstile" phx-hook="RenderCaptcha" />

            <%!-- <label class="flex items-center">
              <.input field={f[:confirm]} type="checkbox" required />
              <span class="text-sm text-slate-500 ml-2">
                Saya menyatakan data di atas sudah benar.
              </span>
            </label> --%>
          </div>

          <%!-- payment channels --%>
          <div :if={@checkout.price_type != :free and @total_price > 0}>
            <p class="py-3 px-6 text-sm font-semibold bg-slate-100 border-y">
              Metode pembayaran
            </p>
            <.async_result :let={channels} assign={@payment_channels}>
              <:loading>
                <div class="flex justify-center text-sm text-slate-500 p-4">
                  <.spinner class="w-4 h-4 mr-2" />
                  <span>Memuat metode pembayaran...</span>
                </div>
              </:loading>

              <div :if={channels} class="pt-3 px-6">
                <%!-- <h3 class="text-lg font-semibold text-gray-900">Metode Pembayaran</h3> --%>
                <div :for={category <- channels} class="pb-6">
                  <p class="text-sm font-semibold mb-2"><%= category.name %></p>
                  <div class={[
                    "grid gap-3",
                    category.code == "qris" && "grid-cols-1",
                    category.code != "qris" && "grid-cols-2 md:grid-cols-3 lg:grid-cols-4"
                  ]}>
                    <div
                      :for={channel <- category.channels}
                      phx-click={
                        JS.push("select_payment_channel",
                          value: %{"id" => category.code <> ":" <> channel.code},
                          target: @submit_target
                        )
                      }
                      class={[
                        "flex items-center justify-center bg-white shadow rounded-md p-2 cursor-pointer border",
                        !payment_channel_selected?(@selected_payment_channel, category, channel) &&
                          "hover:border-primary-500",
                        payment_channel_selected?(@selected_payment_channel, category, channel) &&
                          "border-primary-500"
                      ]}
                    >
                      <img src={channel.logo_url} alt={channel.name} title={channel.name} />
                    </div>
                  </div>
                </div>
              </div>
            </.async_result>
          </div>

          <div :if={@total_price > 0}>
            <p class="py-3 px-6 text-sm font-semibold bg-slate-100 border-y">
              Detail order
            </p>
            <div>
              <div class="flex justify-between border-b border-dashed py-2 px-6">
                <p class="text-sm text-slate-600"><%= Checkout.full_name(@checkout) %></p>
                <p class="text-sm text-slate-600"><.price value={@checkout.price} /></p>
              </div>
              <div class="flex justify-between border-b border-dashed py-2 px-6">
                <p class="text-sm text-slate-600">Diskon</p>
                <p class="text-sm text-slate-600">-<.price value={@checkout.discount_value} /></p>
              </div>
              <%!-- <div class="flex justify-between border-b border-dashed py-2 px-6">
            <p class="text-sm text-slate-600">Angka unik</p>
            <p class="text-sm text-slate-600"><.price value={@checkout.unique_code}/></p>
          </div> --%>
              <div class="flex justify-between py-2 px-6">
                <p class="text-sm text-slate-600 font-bold">Total</p>
                <p class="text-sm text-slate-600 font-bold"><.price value={@total_price} /></p>
              </div>
            </div>
          </div>

          <:actions>
            <div class="px-6 pb-8">
              <button
                id="order-submit"
                phx-hook="UmamiClick"
                data-if={@tracking}
                data-event="order-submit"
                data-url={App.Umami.URL.for(@product)}
                phx-disable-with="Loading..."
                disabled={not @allow_submit}
                type="submit"
                class={[
                  "mt-6 w-full items-center justify-center rounded-md font-semibold transition-all duration-200 ease-in-out",
                  @allow_submit &&
                    "bg-primary-600 p-4 text-lg  text-white focus:shadow hover:bg-primary-700",
                  !@allow_submit && "bg-slate-200 text-slate-400 p-4 cursor-not-allowed"
                ]}
              >
                <span :if={@total_price == 0}>Kirim akses via Email</span>
                <span :if={@total_price > 0}>Bayar <.price value={@total_price} /></span>
              </button>
            </div>
          </:actions>
        </.simple_form>
      </div>
      <%!-- END FORM --%>

      <%!-- <div class="text-center pt-4 mt-6">
        <p class="text-sm text-slate-400 items-center">
          Produk ini disediakan oleh
          <span class="font-semibold text-primary-500">UpKoding</span>
          <.icon
            name="hero-arrow-top-right-on-square"
            class="w-4 h-4 inline-block text-primary-500"
          />
        </p>
      </div> --%>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      case Map.get(assigns, :changeset) do
        nil ->
          product = assigns.product
          variants = App.Products.list_variants_by_product(product, true)
          has_variants = not Enum.empty?(variants)
          images = App.Products.list_images(product)

          socket
          |> assign(assigns)
          |> assign(:product, product)
          |> assign(:enable_captcha, false)
          |> assign(:has_variants, has_variants)
          |> assign(:product_variants, variants)
          |> assign(:images, images)
          |> maybe_select_default_variant(variants)

        changeset ->
          product = Ecto.Changeset.apply_changes(changeset)
          variants = App.Products.list_variants_by_product(product, true)
          has_variants = not Enum.empty?(variants)
          images = App.Products.list_images(product)

          socket
          |> assign(:product, product)
          |> assign(:preview, true)
          |> assign(:enable_captcha, false)
          |> assign(:has_variants, has_variants)
          |> assign(:product_variants, variants)
          |> assign(:images, images)
          |> maybe_select_default_variant(variants)
      end
      |> assign(:checkout_changeset, Checkout.changeset(%Checkout{}, %{}))
      |> assign(:order_changeset, Orders.change_order(%Orders.Order{}))
      |> assign_async(:payment_channels, fn ->
        {:ok, %{payment_channels: Orders.list_payment_channels()}}
      end)
      |> assign(:selected_payment_channel, nil)
      |> assign(:step, "details")

    {:ok, socket}
  end

  @impl true
  def handle_event("select_variant", %{"id" => id}, socket) do
    {:noreply, select_variant(socket, id)}
  end

  @impl true
  def handle_event("select_payment_channel", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_payment_channel, id)}
  end

  @impl true
  def handle_event("step", %{"step" => step}, socket) do
    {:noreply, assign(socket, :step, step)}
  end

  @impl true
  def handle_event("checkout", %{"checkout" => %{"variant_id" => id}}, socket) do
    product = socket.assigns.product
    variants = socket.assigns.product_variants

    socket =
      case Enum.find(variants, &(&1.id == id)) do
        nil ->
          socket

        variant ->
          price_type = if variant.price == 0, do: :free, else: :fixed

          price = %Checkout{
            product: product,
            variant: variant,
            price_type: price_type,
            price: variant.price
          }

          socket
          |> assign(:checkout, price)
          |> assign(:step, "checkout")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("checkout", %{"checkout" => %{"price" => price}}, socket) do
    product = socket.assigns.product
    {price, _} = Integer.parse(price)

    socket =
      with :flexible <- product.price_type,
           true <- price >= product.price do
        # TODO: validate custom price
        co = %Checkout{product: product, price_type: :flexible, price: price}
        send(self(), {:flash, :clear})

        socket
        |> assign(:checkout, co)
        |> assign(:step, "checkout")
      else
        _ ->
          send(self(), {:flash, :warning, "Harga yang Anda masukkan tidak valid"})
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("checkout", _params, socket) do
    product = socket.assigns.product
    price_type = product.price_type

    co =
      case price_type do
        :fixed -> %Checkout{product: product, price_type: price_type, price: product.price}
        :free -> %Checkout{product: product, price_type: price_type, price: 0}
      end

    {:noreply,
     socket
     |> assign(:checkout, co)
     |> assign(:step, "checkout")}
  end

  @impl true
  def handle_event("validate_order", %{"order" => order_params}, socket) do
    params = prepare_order_params(socket, order_params)
    changeset = Order.create_changeset(%Order{}, params)

    {:noreply, assign(socket, :order_changeset, changeset)}
  end

  @impl true
  def handle_event(
        "simulate_order",
        %{"order" => order_params},
        socket
      ) do
    params = prepare_order_params(socket, order_params)
    changeset = Order.create_changeset(%Order{}, params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, _order} ->
        :timer.sleep(500)

        send(
          self(),
          {:flash, :warning, "Produk belum aktif atau Anda sedang dalam mode preview."}
        )

        {:noreply, assign(socket, :order_changeset, changeset)}

      {:error, changeset} ->
        {:noreply, assign(socket, :order_changeset, changeset)}
    end
  end

  @impl true
  def handle_event(
        "create_order",
        _params,
        %{assigns: %{product: %{is_live: false}}} = socket
      ) do
    send(self(), {:flash, :warning, "Produk ini belum aktif"})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "create_order",
        %{"order" => order_params} = form_params,
        socket
      ) do
    if Map.has_key?(form_params, "cf-turnstile-response") do
      :ok = Captcha.verify_token(form_params["cf-turnstile-response"])
    end

    params = prepare_order_params(socket, order_params)
    payment_channel = socket.assigns.selected_payment_channel

    {:ok, draft_order} = Orders.draft_order(params)

    with {:ok, payment} <- Orders.create_payment(draft_order, payment_channel: payment_channel),
         {:ok, order} <- Orders.commit_order(draft_order) do
      send(self(), %{new_order: order, new_payment: payment})
      {:noreply, socket}
    else
      {:error, :provider_error} ->
        send(
          self(),
          {:flash, :error, "Maaf, metode pembayaran yang Anda pilih sedang mengalami gangguan."}
        )

        Orders.delete_order(draft_order)
        {:noreply, socket}

      _ ->
        send(
          self(),
          {:flash, :error, "Gagal membuat pesanan, silahkan coba beberapa saat lagi."}
        )

        Orders.delete_order(draft_order)
        {:noreply, socket}
    end
  end

  defp prepare_order_params(socket, order_params) do
    checkout = socket.assigns.checkout
    product = socket.assigns.product |> App.Repo.preload(:user)
    user = product.user
    user_plan = App.Plans.get(user.plan)
    total = Checkout.total(checkout)
    thanks_page_config = App.Products.ThanksPageConfig.get_or_default(product)

    order_params
    |> Map.put("user", user)
    |> Map.put("product", checkout.product)
    |> Map.put("product_variant", checkout.variant)
    |> Map.put("sub_total", checkout.price)
    |> Map.put("discount_value", checkout.discount_value)
    |> Map.put("total", total)
    |> Map.put("service_fee", user_plan.commission(total))
    |> Map.put("invoice_number", Orders.generate_invoice_number())
    |> Map.put(
      "valid_until",
      Orders.valid_until_hours(Application.fetch_env!(:app, :order_validity_hours))
    )
    |> Map.put("thanks_page_config", Map.from_struct(thanks_page_config))
  end

  defp select_variant(socket, id) do
    assign(socket, :selected_variant_id, id)
  end

  defp maybe_select_default_variant(socket, variants) do
    cond do
      Enum.empty?(variants) ->
        assign(socket, :selected_variant_id, nil)

      true ->
        select_variant(socket, Enum.at(variants, 0).id)
    end
  end

  defp payment_channel_selected?(selected, category, channel) do
    selected == category.code <> ":" <> channel.code
  end
end
