defmodule Mindwendel.IdeasTest do
  use Mindwendel.DataCase
  alias Mindwendel.Factory

  alias Mindwendel.Ideas
  alias Mindwendel.Brainstormings.Idea

  setup do
    user = Factory.insert!(:user)
    brainstorming = Factory.insert!(:brainstorming, users: [user])
    lane = Enum.at(brainstorming.lanes, 0)

    %{
      brainstorming: brainstorming,
      idea:
        Factory.insert!(:idea,
          brainstorming: brainstorming,
          lane: lane,
          inserted_at: ~N[2021-01-01 15:04:30]
        ),
      user: user,
      like: Factory.insert!(:like, :with_idea_and_user),
      lane: lane
    }
  end

  describe "list_ideas_for_brainstorming" do
    test "sorts ideas based on position", %{
      brainstorming: brainstorming,
      lane: lane,
      idea: idea
    } do
      second_idea =
        Factory.insert!(:idea, brainstorming: brainstorming, lane: lane, position_order: 1)

      third_idea =
        Factory.insert!(:idea, brainstorming: brainstorming, lane: lane, position_order: 2)

      ideas_sorted_by_position = Ideas.list_ideas_for_brainstorming(brainstorming.id, lane.id)

      assert Enum.map(ideas_sorted_by_position, & &1.id) == [
               # default is null, therefore idea comes last
               second_idea.id,
               third_idea.id,
               idea.id
             ]
    end
  end

  describe "update_ideas_for_brainstorming_by_likes" do
    test "updates the order position for three ideas", %{
      brainstorming: brainstorming,
      idea: idea,
      lane: lane
    } do
      Ideas.update_ideas_for_brainstorming_by_likes(brainstorming.id, lane.id)
      assert Repo.reload(idea).position_order == 1
    end

    test "update ideas in the correct order", %{
      brainstorming: brainstorming,
      lane: lane,
      user: user,
      idea: idea
    } do
      Factory.insert!(:like, idea: idea, user: user, inserted_at: ~N[2021-01-01 15:04:30])
      another_user = Factory.insert!(:user)
      Factory.insert!(:like, idea: idea, user: another_user, inserted_at: ~N[2021-01-01 15:06:30])
      second_idea = Factory.insert!(:idea, brainstorming: brainstorming, lane: lane)

      Factory.insert!(:like,
        idea: second_idea,
        user: another_user,
        inserted_at: ~N[2021-01-01 15:06:32]
      )

      third_idea = Factory.insert!(:idea, brainstorming: brainstorming, lane: lane)
      Ideas.update_ideas_for_brainstorming_by_likes(brainstorming.id, lane.id)

      query =
        from(idea in Idea,
          where: idea.brainstorming_id == ^brainstorming.id,
          order_by: [asc_nulls_last: idea.position_order]
        )

      ideas_sorted_by_position = Repo.all(query)

      assert ideas_sorted_by_position |> Enum.map(& &1.id) == [
               idea.id,
               second_idea.id,
               third_idea.id
             ]
    end
  end

  describe "update_ideas_for_brainstorming_by_labels" do
    test "updates the order position for three ideas", %{
      brainstorming: brainstorming,
      idea: idea,
      lane: lane
    } do
      Ideas.update_ideas_for_brainstorming_by_labels(brainstorming.id, lane.id)
      assert Repo.reload(idea).position_order == 1
    end

    test "update ideas in the correct order", %{
      brainstorming: brainstorming,
      lane: lane,
      idea: idea
    } do
      second_idea =
        Factory.insert!(:idea,
          brainstorming: brainstorming,
          lane: lane,
          label: Enum.at(brainstorming.labels, 0),
          inserted_at: ~N[2022-01-01 15:06:30]
        )

      third_idea =
        Factory.insert!(:idea,
          brainstorming: brainstorming,
          lane: lane,
          label: Enum.at(brainstorming.labels, 1),
          inserted_at: ~N[2021-01-01 15:06:30]
        )

      Ideas.update_ideas_for_brainstorming_by_labels(brainstorming.id, lane.id)
      ideas_sorted_by_position = Ideas.list_ideas_for_brainstorming(brainstorming.id, lane.id)

      assert ideas_sorted_by_position |> Enum.map(& &1.id) == [
               second_idea.id,
               third_idea.id,
               idea.id
             ]
    end
  end

  describe "update_ideas_for_brainstorming_by_user_move" do
    test "update ideas in the correct order", %{
      brainstorming: brainstorming,
      idea: idea,
      lane: lane
    } do
      second_idea =
        Factory.insert!(:idea,
          brainstorming: brainstorming,
          lane: lane,
          position_order: 1,
          updated_at: ~N[2021-01-01 15:06:30]
        )

      third_idea =
        Factory.insert!(:idea,
          brainstorming: brainstorming,
          lane: lane,
          position_order: 2,
          updated_at: ~N[2021-01-01 15:06:30]
        )

      Ideas.update_ideas_for_brainstorming_by_user_move(brainstorming.id, lane.id, idea.id, 1, 3)

      query =
        from(idea in Idea,
          where: idea.brainstorming_id == ^brainstorming.id and idea.lane_id == ^lane.id,
          order_by: [asc_nulls_last: idea.position_order]
        )

      ideas_sorted_by_position = Repo.all(query)

      assert ideas_sorted_by_position |> Enum.map(& &1.id) == [
               idea.id,
               second_idea.id,
               third_idea.id
             ]
    end
  end
end
