defmodule Presencemedia.Fixtures do
  @moduledoc """
  The made-up data the surface is being designed against.

  There is no database yet — no Ecto dependency at all — so nothing here is
  loaded, only rendered. That is deliberate: the surface is being drawn before
  the spine is built.

  The MEDIA is real, though, and fetched from Wikimedia Commons at play time, so
  what you are looking at is the actual behaviour rather than a mime of it. It
  lives here rather than in a LiveView because two screens now read the same
  presences, and a second copy would be a second thing to keep true.
  """

  # Commons serves a permanent MP3/WebM transcode alongside every upload. We
  # point at those rather than the .ogg and .webm originals for one blunt
  # reason: Safari cannot play Ogg Vorbis at all, and the sources are 9-14 MB
  # apiece for a screen a few hundred pixels wide.
  def commons, do: "https://upload.wikimedia.org/wikipedia/commons/transcoded"

  @doc """
  Every presence in the pool, newest last, each already carrying its creator.
  """
  def presences do
    people = creators()

    # THE HUE IS THE CREATOR'S, not the row's — taken from their position in the
    # roster, so a person is one colour wherever they turn up.
    #
    # Hashing the name into a fixed set of buckets was the obvious thing and the
    # wrong one: fourteen names into ten buckets is four collisions before you
    # start, and in practice it gave seven colours for fourteen people.
    #
    # Spreading them EVENLY over the circle was the second wrong one. It gives
    # every creator a distinct hue and hands consecutive ones consecutive
    # degrees, so the first three neighbours in the list came out red, red-orange
    # and orange — three names apart in the roster is 77 degrees apart on the
    # wheel and reads as the same colour. Neighbours are exactly the pairs that
    # have to be told apart.
    #
    # The golden angle instead: 137.5 degrees between consecutive creators, so
    # anyone standing next to anyone else is most of the wheel away, and the set
    # as a whole still covers it without repeating. It is what phyllotaxis does
    # with leaves for the same reason — never shade the one below you.
    hues =
      people
      |> Enum.with_index()
      |> Map.new(fn {who, i} -> {who, i |> Kernel.*(137.508) |> round() |> Integer.mod(360)} end)

    pool()
    |> Enum.zip(people)
    |> Enum.map(fn {presence, by} -> Map.merge(presence, %{by: by, hue: hues[by]}) end)
  end

  # Real names on real clips. A presence belongs to whoever left it, so the
  # creator is part of the fixture rather than something the page decides.
  defp creators do
    ~w(SARAH MICHAEL DANIEL AMAKA ROSE IBRAHIM TUNDE ELENA KEMI PETER BLESSING ADEOLA LUCAS HANNAH)
  end

  defp pool do
    [
      %{
        kind: "voice",
        when: "07:12",
        len: "0:10",
        from: "them",
        heard: true,
        media: "#{commons()}/9/96/Andy_Mabbett_voice.ogg/Andy_Mabbett_voice.ogg.mp3"
      },
      %{
        kind: "face",
        when: "08:03",
        len: "0:37",
        from: "you",
        heard: true,
        media:
          "#{commons()}/8/8e/WIKITONGUES-_Sedang_speaking_Iban.webm/" <>
            "WIKITONGUES-_Sedang_speaking_Iban.webm.360p.vp9.webm"
      },
      %{
        kind: "voice",
        when: "09:41",
        len: "0:15",
        from: "them",
        heard: true,
        media: "#{commons()}/b/bb/Bettany_Hughes_voice.ogg/Bettany_Hughes_voice.ogg.mp3"
      },
      %{
        kind: "voice",
        when: "11:26",
        len: "0:17",
        from: "you",
        heard: true,
        media: "#{commons()}/0/01/David_Lammy_voice.ogg/David_Lammy_voice.ogg.mp3"
      },
      %{
        kind: "face",
        when: "12:58",
        len: "0:46",
        from: "them",
        heard: true,
        media:
          "#{commons()}/2/26/WIKITONGUES-_Tarkhan_speaking_Jek.webm/" <>
            "WIKITONGUES-_Tarkhan_speaking_Jek.webm.360p.vp9.webm"
      },
      %{
        kind: "voice",
        when: "14:07",
        len: "0:16",
        from: "them",
        heard: true,
        media: "#{commons()}/e/ec/David_Harewood_voice.ogg/David_Harewood_voice.ogg.mp3"
      },
      %{
        kind: "face",
        when: "15:34",
        len: "0:54",
        from: "you",
        heard: true,
        media:
          "#{commons()}/e/ea/WIKITONGUES-_Uladzislau_speaking_Belarusian.webm/" <>
            "WIKITONGUES-_Uladzislau_speaking_Belarusian.webm.360p.vp9.webm"
      },
      %{
        kind: "voice",
        when: "17:19",
        len: "0:18",
        from: "them",
        heard: true,
        media: "#{commons()}/0/0f/Alison_Balsom_voice.ogg/Alison_Balsom_voice.ogg.mp3"
      },
      %{
        kind: "face",
        when: "18:45",
        len: "0:48",
        from: "them",
        heard: false,
        media:
          "#{commons()}/c/c9/WIKITONGUES-_Jeries_speaking_Syriac.webm/" <>
            "WIKITONGUES-_Jeries_speaking_Syriac.webm.360p.vp9.webm"
      },
      %{
        kind: "voice",
        when: "20:02",
        len: "0:16",
        from: "you",
        heard: true,
        media: "#{commons()}/f/fa/Brian_Schmidt_voice.ogg/Brian_Schmidt_voice.ogg.mp3"
      },
      %{
        kind: "face",
        when: "21:30",
        len: "0:56",
        from: "them",
        heard: false,
        media:
          "#{commons()}/2/20/WIKITONGUES-_Yernur_speaking_Kazakh.webm/" <>
            "WIKITONGUES-_Yernur_speaking_Kazakh.webm.360p.vp9.webm"
      },
      %{
        kind: "face",
        when: "22:51",
        len: "0:58",
        from: "them",
        heard: false,
        media:
          "#{commons()}/0/05/WIKITONGUES-_Rizki_speaking_Malay.webm/" <>
            "WIKITONGUES-_Rizki_speaking_Malay.webm.360p.vp9.webm"
      }
    ]
  end
end
