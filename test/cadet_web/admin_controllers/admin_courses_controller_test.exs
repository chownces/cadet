defmodule CadetWeb.AdminCoursesControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.AdminCoursesController

  test "swagger" do
    AdminCoursesController.swagger_definitions()
    AdminCoursesController.swagger_path_update_course_config(nil)
    AdminCoursesController.swagger_path_update_assessment_config(nil)
    AdminCoursesController.swagger_path_update_assessment_types(nil)
  end

  describe "PUT /courses/{courseId}/course_config" do
    @tag authenticate: :admin
    test "succeeds 1", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_course_config(course.id), %{
          "source_chapter" => Enum.random(1..4),
          "source_variant" => "default"
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :admin
    test "succeeds 2", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_course_config(course.id), %{
          "name" => "Data Structures and Algorithms",
          "module_code" => "CS2040S",
          "enable_game" => false,
          "enable_achievements" => false,
          "enable_sourcecast" => true,
          "source_chapter" => Enum.random(1..4),
          "source_variant" => "default",
          "module_help_text" => "help"
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :admin
    test "succeeds 3", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_course_config(course.id), %{
          "name" => "Data Structures and Algorithms",
          "module_code" => "CS2040S",
          "enable_game" => false,
          "enable_achievements" => false,
          "enable_sourcecast" => true,
          "module_help_text" => "help"
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_course_config(course.id), %{
          "source_chapter" => 3,
          "source_variant" => "concurrent"
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid course id", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_course_config(course.id + 1), %{
          "source_chapter" => 3,
          "source_variant" => "concurrent"
        })

      assert response(conn, 400) == "Invalid course id"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_course_config(course.id), %{
          "source_chapter" => 4,
          "source_variant" => "wasm"
        })

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_course_config(course.id), %{
          "name" => "Data Structures and Algorithms",
          "module_code" => "CS2040S",
          "enable_game" => false,
          "enable_achievements" => false,
          "enable_sourcecast" => true,
          "module_help_text" => "help",
          "source_variant" => "default"
        })

      assert response(conn, 400) == "Missing parameter(s)"
    end
  end

  describe "PUT /courses/{courseId}/assessment_config" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      assessment_config = insert(:assessment_config)

      conn =
        put(conn, build_url_assessment_config(assessment_config.course_id), %{
          "early_submission_xp" => 100,
          "hours_before_early_xp_decay" => 24,
          "decay_rate_points_per_hour" => 2
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      assessment_config = insert(:assessment_config)

      conn =
        put(conn, build_url_assessment_config(assessment_config.course_id), %{
          "early_submission_xp" => 100,
          "hours_before_early_xp_decay" => 24,
          "decay_rate_points_per_hour" => 2
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params", %{conn: conn} do
      assessment_config = insert(:assessment_config)

      conn =
        put(conn, build_url_assessment_config(assessment_config.course_id), %{
          "early_submission_xp" => 100,
          "hours_before_early_xp_decay" => -1,
          "decay_rate_points_per_hour" => 200
        })

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      assessment_config = insert(:assessment_config)

      conn =
        put(conn, build_url_assessment_config(assessment_config.course_id), %{
          "hours_before_early_xp_decay" => 24,
          "decay_rate_points_per_hour" => 2
        })

      assert response(conn, 400) == "Missing parameter(s)"
    end
  end

  describe "PUT /courses/{courseId}/assessment_types" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_assessment_types(course.id), %{
          "assessment_types" => ["Missions", "Quests", "Contests"]
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_assessment_types(course.id), %{
          "assessment_types" => ["Missions", "Quests", "Contests"]
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params 1", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_assessment_types(course.id), %{
          "assessment_types" => "Missions"
        })

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params 2", %{conn: conn} do
      course = insert(:course)

      conn =
        put(conn, build_url_assessment_types(course.id), %{
          "assessment_types" => [1, "Missions", "Quests"]
        })

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      course = insert(:course)

      conn = put(conn, build_url_assessment_types(course.id), %{})

      assert response(conn, 400) == "Missing parameter(s)"
    end
  end

  defp build_url_course_config(course_id), do: "/v2/admin/courses/#{course_id}/course_config"

  defp build_url_assessment_config(course_id),
    do: "/v2/admin/courses/#{course_id}/assessment_config"

  defp build_url_assessment_types(course_id),
    do: "/v2/admin/courses/#{course_id}/assessment_types"
end
