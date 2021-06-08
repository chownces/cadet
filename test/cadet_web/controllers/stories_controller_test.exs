defmodule CadetWeb.StoriesControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query

  alias Cadet.Courses.Course
  alias Cadet.Repo
  alias Cadet.Stories.Story
  alias CadetWeb.StoriesController

  setup do
    valid_params = %{
      open_at: Timex.shift(Timex.now(), days: 1),
      close_at: Timex.shift(Timex.now(), days: Enum.random(2..30)),
      is_published: false,
      filenames: ["mission-1.txt"],
      title: "Mission1",
      image_url: "http://example.com"
    }

    updated_params = %{
      title: "Mission2",
      image_url: "http://example.com/new"
    }

    {:ok, %{valid_params: valid_params, updated_params: updated_params}}
  end

  test "swagger" do
    StoriesController.swagger_definitions()
    StoriesController.swagger_path_index(nil)
    StoriesController.swagger_path_create(nil)
    StoriesController.swagger_path_delete(nil)
    StoriesController.swagger_path_update(nil)
  end

  describe "unauthenticated" do
    test "GET /v2/course/{courseId}/stories/", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url(course.id), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "POST /v2/course/{courseId}/stories/", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url(course.id), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "DELETE /v2/course/{courseId}/stories/:storyid", %{conn: conn} do
      course = insert(:course)
      conn = delete(conn, build_url(course.id, "storyid"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "POST /v2/course/{courseId}/stories/:storyid", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url(course.id, "storyid"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /v2/course/{courseId}/stories" do
    @tag authenticate: :student
    test "student permission, only obtain published open stories from own course", %{
      conn: conn,
      valid_params: params
    } do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      insert(:story, %{course: course})
      insert(:story, %{Map.put(params, :course, course) | :is_published => true})
      insert(:story, %{Map.put(params, :course, course) | :open_at => one_week_ago})

      insert(:story, %{
        Map.put(params, :course, course)
        | :is_published => true,
          :open_at => one_week_ago
      })

      insert(:story, %{
        Map.put(params, :course, build(:course))
        | :is_published => true,
          :open_at => one_week_ago
      })

      {:ok, resp} =
        conn
        |> get(build_url(course_id))
        |> response(200)
        |> Jason.decode()

      assert Enum.count(resp) == 1
    end

    @tag authenticate: :staff
    test "obtain all stories from own course", %{conn: conn, valid_params: params} do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      insert(:story, %{course: course})
      insert(:story, %{Map.put(params, :course, course) | :is_published => true})
      insert(:story, %{Map.put(params, :course, course) | :open_at => one_week_ago})

      insert(:story, %{
        Map.put(params, :course, course)
        | :is_published => true,
          :open_at => one_week_ago
      })

      insert(:story, %{course: build(:course)})

      {:ok, resp} =
        conn
        |> get(build_url(course_id))
        |> response(200)
        |> Jason.decode()

      assert Enum.count(resp) == 4
    end

    @tag authenticate: :staff
    test "All fields are present and in the right format", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()

      insert(:story, %{course: course})

      {:ok, [resp]} =
        conn
        |> get(build_url(course_id))
        |> response(200)
        |> Jason.decode()

      required_fields = ~w(openAt closeAt isPublished id title filenames imageUrl courseId)

      Enum.each(required_fields, fn required_field ->
        value = resp[required_field]
        assert value != nil

        case required_field do
          "id" -> assert is_integer(value)
          "filenames" -> assert is_list(value)
          "isPublished" -> assert is_boolean(value)
          "courseId" -> assert is_integer(value)
          _ -> assert is_binary(value)
        end
      end)
    end
  end

  describe "DELETE /v2/course/{courseId}/stories/:storyid" do
    @tag authenticate: :student
    test "student permission, forbidden", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()
      story = insert(:story, %{course: course})

      conn = delete(conn, build_url(course_id, story.id), %{})
      assert response(conn, 403) =~ "User not allowed to manage stories"
    end

    @tag authenticate: :staff
    test "staff successfully deletes story from own course", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()
      story = insert(:story, %{course: course})

      resp = delete(conn, build_url(course_id, story.id), %{})

      assert Story
             |> where(id: ^story.id)
             |> Repo.one() == nil

      assert response(resp, 204) == ""
    end

    @tag authenticate: :staff
    test "staff fails to delete story from another course", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      story = insert(:story, %{course: build(:course)})

      resp = delete(conn, build_url(course_id, story.id), %{})

      assert response(resp, 403) == "User not allowed to manage stories from another course"
    end
  end

  describe "POST /v2/course/{courseId}/stories/" do
    @tag authenticate: :student
    test "student permission, forbidden", %{conn: conn, valid_params: params} do
      course_id = conn.assigns[:course_id]

      conn = post(conn, build_url(course_id), params)
      assert response(conn, 403) =~ "User not allowed to manage stories"
    end

    @tag authenticate: :staff
    test "creates a new story", %{conn: conn, valid_params: params} do
      course_id = conn.assigns[:course_id]

      conn = post(conn, build_url(course_id), stringify_camelise_keys(params))

      inserted_story =
        Story
        |> where(title: ^params.title)
        |> Repo.one()

      params = Map.put(params, :course_id, course_id)
      assert inserted_story |> Map.take(Map.keys(params)) == params
      assert response(conn, 200) == ""
    end
  end

  describe "POST /v2/course/{courseId}/stories/:storyid" do
    @tag authenticate: :student
    test "student permission, forbidden", %{conn: conn, valid_params: params} do
      course_id = conn.assigns[:course_id]

      conn = post(conn, build_url(course_id), %{"story" => params})
      assert response(conn, 403) =~ "User not allowed to manage stories"
    end

    @tag authenticate: :staff
    test "staff successfully updates a story from own course", %{
      conn: conn,
      updated_params: updated_params
    } do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()
      story = insert(:story, %{course: course})

      conn =
        post(conn, build_url(course_id, story.id), %{
          "story" => stringify_camelise_keys(updated_params)
        })

      updated_story = Repo.get(Story, story.id)
      updated_params = Map.put(updated_params, :course_id, course_id)

      assert updated_story |> Map.take(Map.keys(updated_params)) == updated_params

      assert response(conn, 200) == ""
    end

    @tag authenticate: :staff
    test "staff fails to update a story from another course", %{
      conn: conn,
      updated_params: updated_params
    } do
      course_id = conn.assigns[:course_id]
      story = insert(:story, %{course: build(:course)})

      resp =
        post(conn, build_url(course_id, story.id), %{
          "story" => stringify_camelise_keys(updated_params)
        })

      assert response(resp, 403) == "User not allowed to manage stories from another course"
    end
  end

  defp build_url(course_id), do: "/v2/course/#{course_id}/stories"
  defp build_url(course_id, story_id), do: "#{build_url(course_id)}/#{story_id}"

  defp stringify_camelise_keys(map) do
    for {key, value} <- map, into: %{}, do: {key |> Atom.to_string() |> Recase.to_camel(), value}
  end
end
