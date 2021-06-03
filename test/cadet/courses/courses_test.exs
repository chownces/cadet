defmodule Cadet.CourseTest do
  use Cadet.DataCase

  alias Cadet.{Courses, Repo}
  alias Cadet.Courses.{Group, Sourcecast, SourcecastUpload}

  describe "get course config" do
    test "succeeds" do
      course = insert(:course)
      {:ok, course} = Courses.get_course_config(course.id)
      assert course.name == "Programming Methodology"
      assert course.module_code == "CS1101S"
      assert course.viewable == true
      assert course.enable_game == true
      assert course.enable_achievements == true
      assert course.enable_sourcecast == true
      assert course.source_chapter == 1
      assert course.source_variant == "default"
      assert course.module_help_text == "Help Text"
    end

    test "returns with error for invalid course id" do
      course = insert(:course)
      assert {:error, {status, message}} = Courses.get_course_config(course.id + 1)
      assert status = :bad_request
      assert message = "Invalid course id"
    end
  end

  describe "update course config" do
    test "succeeds (without sublanguage update)" do
      course = insert(:course)

      {:ok, updated_course} =
        Courses.update_course_config(course.id, %{
          name: "Data Structures and Algorithms",
          module_code: "CS2040S",
          viewable: false,
          enable_game: false,
          enable_achievements: false,
          enable_sourcecast: false,
          module_help_text: ""
        })

      assert updated_course.name == "Data Structures and Algorithms"
      assert updated_course.module_code == "CS2040S"
      assert updated_course.viewable == false
      assert updated_course.enable_game == false
      assert updated_course.enable_achievements == false
      assert updated_course.enable_sourcecast == false
      assert updated_course.source_chapter == 1
      assert updated_course.source_variant == "default"
      assert updated_course.module_help_text == nil
    end

    test "succeeds (with sublanguage update)" do
      course = insert(:course)
      new_chapter = Enum.random(1..4)

      {:ok, updated_course} =
        Courses.update_course_config(course.id, %{
          name: "Data Structures and Algorithms",
          module_code: "CS2040S",
          viewable: false,
          enable_game: false,
          enable_achievements: false,
          enable_sourcecast: false,
          source_chapter: new_chapter,
          source_variant: "default",
          module_help_text: "help"
        })

      assert updated_course.name == "Data Structures and Algorithms"
      assert updated_course.module_code == "CS2040S"
      assert updated_course.viewable == false
      assert updated_course.enable_game == false
      assert updated_course.enable_achievements == false
      assert updated_course.enable_sourcecast == false
      assert updated_course.source_chapter == new_chapter
      assert updated_course.source_variant == "default"
      assert updated_course.module_help_text == "help"
    end

    test "returns with error for invalid course id" do
      course = insert(:course)
      new_chapter = Enum.random(1..4)

      assert {:error, {status, message}} =
               Courses.update_course_config(course.id + 1, %{
                 source_chapter: new_chapter,
                 source_variant: "default"
               })

      assert status = :bad_request
      assert message = "Invalid course id"
    end

    test "returns with error for failed updates" do
      course = insert(:course)

      assert {:error, changeset} =
               Courses.update_course_config(course.id, %{
                 source_chapter: 0,
                 source_variant: "default"
               })

      assert %{source_chapter: ["is invalid"]} = errors_on(changeset)

      assert {:error, changeset} =
               Courses.update_course_config(course.id, %{source_chapter: 2, source_variant: "gpu"})

      assert %{source_variant: ["is invalid"]} = errors_on(changeset)
    end
  end

  # describe "Sourcecast" do
  #   setup do
  #     on_exit(fn -> File.rm_rf!("uploads/test/sourcecasts") end)
  #   end

  #   test "upload file to folder then delete it" do
  #     uploader = insert(:user, %{role: :staff})

  #     upload = %Plug.Upload{
  #       content_type: "audio/wav",
  #       filename: "upload.wav",
  #       path: "test/fixtures/upload.wav"
  #     }

  #     result =
  #       Courses.upload_sourcecast_file(uploader, %{
  #         title: "Test Upload",
  #         audio: upload,
  #         playbackData:
  #           "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}"
  #       })

  #     assert {:ok, sourcecast} = result
  #     path = SourcecastUpload.url({sourcecast.audio, sourcecast})
  #     assert path =~ "/uploads/test/sourcecasts/upload.wav"

  #     deleter = insert(:user, %{role: :staff})
  #     assert {:ok, _} = Courses.delete_sourcecast_file(deleter, sourcecast.id)
  #     assert Repo.get(Sourcecast, sourcecast.id) == nil
  #     refute File.exists?("uploads/test/sourcecasts/upload.wav")
  #   end
  # end

  # describe "get_or_create_group" do
  #   test "existing group" do
  #     group = insert(:group)

  #     {:ok, group_db} = Courses.get_or_create_group(group.name)

  #     assert group_db.id == group.id
  #     assert group_db.leader_id == group.leader_id
  #   end

  #   test "non-existent group" do
  #     group_name = params_for(:group).name

  #     {:ok, _} = Courses.get_or_create_group(group_name)

  #     group_db =
  #       Group
  #       |> where(name: ^group_name)
  #       |> Repo.one()

  #     refute is_nil(group_db)
  #   end
  # end

  # describe "insert_or_update_group" do
  #   test "existing group" do
  #     group = insert(:group)
  #     group_params = params_with_assocs(:group, name: group.name)
  #     Courses.insert_or_update_group(group_params)

  #     updated_group =
  #       Group
  #       |> where(name: ^group.name)
  #       |> Repo.one()

  #     assert updated_group.id == group.id
  #     assert updated_group.leader_id == group_params.leader_id
  #   end

  #   test "non-existent group" do
  #     group_params = params_with_assocs(:group)
  #     Courses.insert_or_update_group(group_params)

  #     updated_group =
  #       Group
  #       |> where(name: ^group_params.name)
  #       |> Repo.one()

  #     assert updated_group.leader_id == group_params.leader_id
  #   end
  # end
end
