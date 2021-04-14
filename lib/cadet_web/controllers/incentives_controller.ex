defmodule CadetWeb.IncentivesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Incentives.{Achievements, Goals}

  def index_achievements(conn, _) do
    render(conn, "index_achievements.json", achievements: Achievements.get())
  end

  def index_goals(conn, _) do
    render(conn, "index_goals_with_progress.json",
      goals: Goals.get_with_progress(conn.assigns.current_user)
    )
  end

  def update_progress(conn, %{"uuid" => uuid, "userid" => userid, "progress" => progress}) do
    progress
    |> json_to_progress(uuid, userid)
    |> Goals.upsert_progress(uuid, userid)
    |> handle_standard_result(conn)
  end

  defp json_to_progress(json, uuid, userid) do
  json =
    json
    |> snake_casify_string_keys_recursive()
  %{count: Map.get(json, "count"),
    completed: Map.get(json, "completed"),
    goal_uuid: uuid,
    user_id: String.to_integer(userid)}
  end

  swagger_path :index_achievements do
    get("/achievements")

    summary("Gets achievements")
    security([%{JWT: []}])

    response(200, "OK", Schema.array(:Achievement))
    response(401, "Unauthorised")
  end

  swagger_path :index_goals do
    get("/self/goals")

    summary("Gets goals, including user's progress")
    security([%{JWT: []}])

    response(200, "OK", Schema.array(:GoalWithProgress))
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Achievement:
        swagger_schema do
          description("An achievement")

          properties do
            uuid(
              :string,
              "Achievement UUID",
              format: :uuid
            )

            title(
              :string,
              "Achievement title"
            )

            ability(
              :string,
              "Achievement ability i.e. category"
            )

            cardBackground(
              :string,
              "URL of the achievement's background image"
            )

            release(
              :string,
              "Open date, in ISO 8601 format"
            )

            deadline(
              :string,
              "Close date, in ISO 8601 format"
            )

            isTask(
              :boolean,
              "Whether the achievement is a task"
            )

            position(
              :integer,
              "Position of the achievement in the list"
            )

            view(
              ref(:AchievementView),
              "View properties"
            )

            goalUuids(
              schema_array(:string, format: :uuid),
              "Goal UUIDs"
            )

            prerequisiteUuids(
              schema_array(:string, format: :uuid),
              "Prerequisite achievement UUIDs"
            )
          end
        end,
      AchievementView:
        swagger_schema do
          description("Achievement view properties")

          properties do
            coverImage(
              :string,
              "URL of the image for the view"
            )

            description(
              :string,
              "Achievement description"
            )

            completionText(
              :string,
              "Text to show when achievement is completed"
            )
          end
        end,
      Goal:
        swagger_schema do
          description("Goals, including user's progress")

          properties do
            uuid(
              :string,
              "Goal UUID",
              format: :uuid
            )

            text(
              :string,
              "Text to show when goal is completed"
            )

            maxXp(
              :integer,
              "Total EXP for this goal"
            )

            type(
              :string,
              "Goal type"
            )

            meta(
              :object,
              "Goal satisfication information"
            )
          end
        end,
      GoalWithProgress:
        swagger_schema do
          description("Goals, including user's progress")

          properties do
            uuid(
              :string,
              "Goal UUID",
              format: :uuid
            )

            completed(
              :boolean,
              "Whether the goal has been completed by the user"
            )

            text(
              :string,
              "Text to show when goal is completed"
            )

            xp(
              :integer,
              "EXP currently attained by the user for this goal"
            )

            maxXp(
              :integer,
              "Total EXP for this goal"
            )

            type(
              :string,
              "Goal type"
            )

            meta(
              :object,
              "Goal satisfication information"
            )
          end
        end
    }
  end
end
