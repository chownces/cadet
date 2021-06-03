defmodule Cadet.CourseTest do
  use Cadet.DataCase

  alias Cadet.{Courses, Repo}
  alias Cadet.Courses.{Group, Sourcecast, SourcecastUpload}

  describe "get sublanguage" do
    test "succeeds" do
      course = insert(:course, %{source_chapter: 3, source_variant: "concurrent"})
      {:ok, sublanguage} = Courses.get_sublanguage(course.id)
      assert sublanguage.source_chapter == 3
      assert sublanguage.source_variant == "concurrent"
    end

    test "returns with error for invalid course id" do
      course = insert(:course)
      assert {:error, _} = Courses.get_sublanguage(course.id + 1)
    end
  end

  describe "update sublanguage" do
    test "succeeds" do
      course = insert(:course)
      new_chapter = Enum.random(1..4)
      {:ok, sublanguage} = Courses.update_sublanguage(course.id, new_chapter, "default")
      assert sublanguage.source_chapter == new_chapter
      assert sublanguage.source_variant == "default"
    end

    test "returns with error for invalid course id" do
      course = insert(:course)
      new_chapter = Enum.random(1..4)
      assert {:error, _} = Courses.update_sublanguage(course.id + 1, new_chapter, "default")
    end

    test "returns with error for failed updates" do
      course = insert(:course)
      assert {:error, changeset} = Courses.update_sublanguage(course.id, 0, "default")
      assert %{source_chapter: ["is invalid"]} = errors_on(changeset)

      assert {:error, changeset} = Courses.update_sublanguage(course.id, 2, "gpu")
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
