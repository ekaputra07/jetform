defmodule AppWeb.CustomComponents do
  @moduledoc """
  Provides custom UI components.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use AppWeb, :verified_routes

  alias Phoenix.LiveView.JS
  import Phoenix.HTML
  import AppWeb.CoreComponents

  @doc """
  Returns app info.
  """
  def app_info(:name) do
    Application.fetch_env!(:app, :app_name)
  end

  def app_info(:tagline) do
    Application.fetch_env!(:app, :app_tagline)
  end

  def captcha_sitekey() do
    Application.fetch_env!(:app, :captcha)[:site_key]
  end

  attr :page_info, :map, default: %{}

  def seo_tags(assigns) do
    ~H"""
    <%!-- general --%>
    <link rel="canonical" href={@page_info.url} />
    <meta name="description" content={@page_info.description} />
    <%!-- OG --%>
    <meta property="og:title" content={@page_info.title} />
    <meta property="og:type" content={@page_info.type} />
    <meta property="og:image" content={@page_info.image} />
    <meta property="og:url" content={@page_info.url} />
    <meta property="og:description" content={@page_info.description} />
    <meta property="og:image:url" content={@page_info.image} />
    <meta property="og:image:alt" content={@page_info.title} />
    <%!-- Twitter --%>
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:site" content="@jetform_app" />
    <meta name="twitter:title" content={@page_info.title} />
    <meta name="twitter:image" content={@page_info.image} />
    <meta name="twitter:image:alt" content={@page_info.title} />
    <meta name="twitter:description" content={@page_info.description} />
    """
  end

  @doc """
  Renders delimited number.
  5000 become `5,000`
  """
  attr :value, :integer, required: true

  def delimited_number(assigns) do
    ~H"""
    <%= App.Utils.Commons.delimited_number(@value) %>
    """
  end

  @doc """
  Renders delimited price with currency prefix.
  5000 become `Rp. 5,000`
  """
  attr :value, :integer, required: true

  def price(assigns) do
    ~H"""
    <%= App.Utils.Commons.format_price(@value) %>
    """
  end

  @doc """
  Renders datetime on specific Indonesian timezones.
  """
  attr :value, :any, required: true
  attr :tz, :string, default: "Asia/Jakarta"
  attr :show_label, :boolean, default: false
  attr :mode, :string, values: ["compact", "verbose"], default: "compact"
  attr :compact_fmt, :string, default: "%d/%m/%Y %H:%M"
  attr :verbose_fmt, :string, default: "%d %B %Y %H:%M"

  def indo_datetime(assigns) do
    label = if assigns.show_label, do: " " <> App.Users.tz_label(assigns.tz), else: ""

    format =
      case assigns.mode do
        "compact" -> assigns.compact_fmt <> label
        "verbose" -> assigns.verbose_fmt <> label
      end

    value =
      Timex.to_datetime(assigns.value, assigns.tz)
      |> Timex.format!(format, :strftime)

    assigns = assign(assigns, :value, value)

    ~H"<%= @value %>"
  end

  @doc """
  Renders time from given seconds.
  """
  attr :value, :integer, required: true

  def seconds_to_time(assigns) do
    # assigns =  assign(assigns, :time, Timex.Duration.from_seconds(assigns.value))
    ~H"""
    <%= Timex.Duration.from_seconds(@value) |> Timex.Duration.to_time!() %>
    """
  end

  @doc """
  Renders a Gravatar image.

  ## Examples

      <.gravatar email={"hello@example.com"} size="32" default="404" class="w-8 h-8" />
  """
  attr :email, :string, required: true
  attr :size, :string, default: "64"
  attr :default, :string, default: "retro"
  attr :rest, :global

  def gravatar(assigns) do
    assigns =
      assigns
      |> assign(:email, String.downcase(assigns.email))
      |> assign(
        :hash,
        :crypto.hash(:sha256, assigns.email) |> Base.encode16() |> String.downcase()
      )

    ~H"""
    <img
      src={"https://gravatar.com/avatar/#{assigns.hash}?s=#{assigns.size}&d=#{assigns.default}"}
      {@rest}
    />
    """
  end

  attr :class, :string, default: "w-6 h-6"

  def spinner(assigns) do
    ~H"""
    <div role="status">
      <svg
        aria-hidden="true"
        class={["inline text-gray-200 animate-spin dark:text-gray-600 fill-blue-600", @class]}
        viewBox="0 0 100 101"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
          fill="currentColor"
        />
        <path
          d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
          fill="currentFill"
        />
      </svg>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  @doc """
  Renders single menu item.
  """
  def menu_item(%{menu: %{path: _}} = assigns) do
    ~H"""
    <li>
      <.link
        navigate={@menu.path}
        id={@menu.icon}
        class="flex items-center p-2 text-base text-gray-900 rounded-md hover:bg-gray-100 group dark:text-gray-200 dark:hover:bg-gray-700 dark:bg-gray-700"
      >
        <.icon
          :if={@menu.icon}
          name={@menu.icon}
          class="w-5 h-5 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
        />
        <span class="ml-3" sidebar-toggle-item><%= @menu.title %></span>
      </.link>
    </li>
    """
  end

  def menu_item(%{menu: %{children: _}} = assigns) do
    ~H"""
    <li>
      <button
        type="button"
        class="flex items-center w-full p-2 text-base text-gray-900 transition duration-75 rounded-md group hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-700"
        aria-controls="dropdown-playground"
        data-collapse-toggle="dropdown-playground"
      >
        <.icon
          :if={@menu.icon}
          name={@menu.icon}
          class="w-5 h-5 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
        />
        <span class="flex-1 ml-3 text-left whitespace-nowrap" sidebar-toggle-item>
          <%= @menu.title %>
        </span>
        <svg
          sidebar-toggle-item
          class="w-5 h-5"
          fill="currentColor"
          viewBox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            fill-rule="evenodd"
            d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
            clip-rule="evenodd"
          >
          </path>
        </svg>
      </button>
      <ul id="dropdown-playground" class="space-y-2 py-2 xhidden">
        <%= for child <- @menu.children do %>
          <.link
            navigate={child.path}
            class="text-base text-gray-900 rounded-md flex items-center p-2 group hover:bg-gray-100 transition duration-75 pl-11 dark:text-gray-200 dark:hover:bg-gray-700 xbg-gray-100 xdark:bg-gray-700"
          >
            <%= child.title %>
          </.link>
        <% end %>
      </ul>
    </li>
    """
  end

  def chevron_left(assigns) do
    ~H"""
    <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
      <path
        fill-rule="evenodd"
        d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
        clip-rule="evenodd"
      >
      </path>
    </svg>
    """
  end

  def chevron_right(assigns) do
    ~H"""
    <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
      <path
        fill-rule="evenodd"
        d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
        clip-rule="evenodd"
      >
      </path>
    </svg>
    """
  end

  attr :meta, :map, required: true
  attr :on_click, :string, default: "change_page"

  def pagination(assigns) do
    ~H"""
    <div :if={@meta} class="flex items-center mb-4 sm:mb-0">
      <%!-- prev --%>
      <button
        :if={@meta.has_previous_page?}
        phx-click={JS.push(@on_click, value: %{page: @meta.previous_page}, page_loading: true)}
        class="inline-flex justify-center p-1 text-gray-500 rounded cursor-pointer hover:text-gray-900 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
      >
        <.chevron_left />
      </button>
      <span
        :if={!@meta.has_previous_page?}
        class="inline-flex justify-center p-1 text-gray-300 rounded cursor-pointer dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
      >
        <.chevron_left />
      </span>
      <%!-- next --%>
      <button
        :if={@meta.has_next_page?}
        phx-click={JS.push(@on_click, value: %{page: @meta.next_page}, page_loading: true)}
        class="inline-flex justify-center p-1 mr-2 text-gray-500 rounded cursor-pointer hover:text-gray-900 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
      >
        <.chevron_right />
      </button>
      <span
        :if={!@meta.has_next_page?}
        class="inline-flex justify-center p-1 text-gray-300 rounded cursor-pointer dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
      >
        <.chevron_right />
      </span>

      <%!-- page info --%>
      <span class="text-sm font-normal text-gray-500 dark:text-gray-400">
        Halaman
        <span class="font-semibold text-gray-900 dark:text-white">
          <%= @meta.current_page %>
        </span>
        dari
        <span class="font-semibold text-gray-900 dark:text-white">
          <%= @meta.total_pages %>
        </span>
      </span>
    </div>
    """
  end

  attr :user, :map, required: true
  slot :inner_block

  def admin_block(assigns) do
    ~H"""
    <div
      :if={@user.role == :admin}
      class="p-4 mb-4 rounded-md bg-yellow-50 dark:bg-gray-800 dark:text-yellow-400 border border-2 border-dashed border-red-600"
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :config, :map, required: true
  attr :order, :map, required: true
  attr :brand_info, :map, required: true

  def thanks_message(assigns) do
    rendered_config = App.Products.ThanksPageConfig.render(assigns.config, assigns.order)
    assigns = assign(assigns, :config, rendered_config)

    ~H"""
    <div id="thanks-page" class="flex flex-col items-center justify-center h-screen">
      <div :if={@config.type == "redirect"} class="sm:p-10">
        <p class="text-lg text-slate-600 mx-auto max-w-lg text-center mb-2">
          Customer akan diarahkan ke:
        </p>
        <p class="text-base text-slate-500 mx-auto max-w-lg text-center">
          <%= @config.redirect_url %>
        </p>
      </div>

      <div
        :if={@config.type == "message"}
        class="flex flex-col justify-center p-10 md:py-20 bg-white shadow-lg rounded-md border"
      >
        <%= if @config.show_brand_logo and @brand_info[:logo] do %>
          <img
            src={@brand_info[:logo]}
            class="w-[128px] h-[128px] rounded-full mx-auto border shadow-lg mb-3"
          />
        <% else %>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            x="0px"
            y="0px"
            width="150"
            height="150"
            viewBox="0 0 48 48"
            class="mx-auto"
          >
            <path fill="#c8e6c9" d="M44,24c0,11-9,20-20,20S4,35,4,24S13,4,24,4S44,13,44,24z"></path>
            <polyline
              fill="none"
              stroke="#4caf50"
              stroke-miterlimit="10"
              stroke-width="4"
              points="14,24 21,31 36,16"
            >
            </polyline>
          </svg>
        <% end %>

        <p class="text-2xl text-slate-400 mx-auto mb-10">
          <span><%= @config.title %></span>
        </p>

        <div class={[
          "text-lg text-slate-600 mx-auto max-w-lg message",
          if(@config.message_left_aligned, do: "text-left", else: "text-center")
        ]}>
          <%= raw(@config.message) %>
        </div>

        <.link
          :if={@order.status != :free}
          href={~p"/invoices/#{@order.id}"}
          class="mt-10 text-sm text-primary-400 mx-auto items-center flex hover:underline"
        >
          INVOICE NO. #<%= @order.invoice_number %>
        </.link>
      </div>
      <p :if={@config.type == "message"} class="text-center pt-4">
        <.link
          navigate={AppWeb.Utils.marketing_site()}
          target="_blank"
          class="mx-auto justify-center items-start text-xs font-normal text-slate-400/50 rounded-md border border-slate-400/50 p-1 px-2"
        >
          Powered by JetForm
        </.link>
      </p>
    </div>
    """
  end
end
