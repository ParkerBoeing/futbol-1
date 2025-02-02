require 'spec_helper.rb'

RSpec.describe StatTracker do
  before do
    games_test_csv = './spec/fixture/game_test.csv'
    game_teams_test_csv = './spec/fixture/game_team_test.csv'
    team_test_csv = './spec/fixture/team_test.csv'

    @locations = {
      games: games_test_csv,
      teams: team_test_csv,
      game_teams: game_teams_test_csv
    }

    @stat_tracker = StatTracker.new(@locations)
  end

  describe "#exists" do
    it "exists" do
      expect(@stat_tracker).to be_a(StatTracker)
    end

    it "has readable attributes" do
      expect(@stat_tracker.games).to be_a(Array)
      expect(@stat_tracker.teams).to be_a(Array)
      expect(@stat_tracker.game_teams).to be_a(Array)

    end
  end

  describe "#from_csv" do
    it "creates game objects" do
      expect(@stat_tracker.games[0]).to be_a(Game)
      expect(@stat_tracker.games.count).to eq(52)
    end

    it 'creates team_games objects' do
      expect(@stat_tracker.game_teams[0]).to be_a(GameTeam)
      expect(@stat_tracker.game_teams.count).to eq(269)
      expect(@stat_tracker.game_teams)
    end

    it "creates team objects" do
      expect(@stat_tracker.teams[0]).to be_a(Team)
      expect(@stat_tracker.teams.count).to eq(32)
      expect(@stat_tracker.teams)
    end
  end

  describe "#game_statics" do
    it "#highest_total_score" do
      expect(@stat_tracker.highest_total_score).to eq(6)
    end

    it "#lowest_total_score" do
      expect(@stat_tracker.lowest_total_score).to eq(1)
    end

    it "#percentage_home_wins" do
      expect(@stat_tracker.percentage_home_wins).to eq( 0.46)
    end

    it "#percentage_visitor_wins" do
      expect(@stat_tracker.percentage_visitor_wins).to eq(0.37)
    end

    it "#average_goals_per_game" do
      expect(@stat_tracker.average_goals_per_game).to eq(3.71)
    end

    it "#percentage_ties" do
      expect(@stat_tracker.percentage_ties).to eq(0.17)
    end

    it "#count_of_games_by_season" do
    expected = {
      "20122013" => 20,
      "20132014" => 25,
      "20142015" => 2,
      "20162017" => 5
    }
    expect(@stat_tracker.count_of_games_by_season).to eq(expected)
    end
  end

  describe '#league_statics' do
    it '#count_of_teams' do
      expect(@stat_tracker.count_of_teams).to eq(32)
    end

    it "can find the average goals per season" do
      expect(@stat_tracker.average_goals_by_season).to eq({
        "20122013"=>3.9,
        "20132014"=>3.64,
        "20142015"=>5.0,
        "20162017"=>2.8
      })
    end

    it '#count_of_teams' do
      expect(@stat_tracker.count_of_teams).to eq(32)
    end

    it "can find the average goals per season" do
      expect(@stat_tracker.average_goals_by_season).to eq({
        "20122013"=>3.9,
        "20132014"=>3.64,
        "20142015"=>5.0,
        "20162017"=>2.8
      })
    end

    it "#average_goals_by_team" do
    expected = {
      "14"    =>1.9231, 
      "15"    =>1.6923, 
      "16"    =>2.1379, 
      "17"    =>1.9286, 
      "19"    =>1.6667, 
      "2"     =>1.8333, 
      "20"    =>1.75, 
      "21"    =>1.7143, 
      "24"    => 2.3529,
      "25"    => 2.5,
      "26"    => 2.1304,
      "28"    =>2.4, 
      "3"     =>1.8065, 
      "30"    =>1.875, 
      "4"     =>1.0, 
      "5"     =>1.9, 
      "6"     =>2.7273, 
      "8"     =>1.7273, 
      "9"     =>2.1818
    }
    expect(@stat_tracker.average_goals_by_team).to eq(expected)
    end

    it "#best_offense" do
    expect(@stat_tracker.best_offense).to eq("FC Dallas")
    end

    it "#worst_offense" do
    expect(@stat_tracker.worst_offense).to eq("Chicago Fire")
    end

    it "#lowest_scoring_visitor" do
    expect(@stat_tracker.lowest_scoring_visitor).to eq("Seattle Sounders FC")
    end

    it "#lowest_scoring_home_team" do
    expect(@stat_tracker.lowest_scoring_home_team).to eq("Chicago Fire")
    end

    it 'can calculate #highest_scoring_visitor' do
      expect(@stat_tracker.highest_scoring_visitor).to eq( "Chicago Red Stars")
    end

    it "#highest_scoring_home_team" do
      expect(@stat_tracker.highest_scoring_home_team).to eq("Seattle Sounders FC")
    end
  end

  describe "#season_statistics" do
    it "#most_tackles" do
      expect(@stat_tracker.most_tackles("20122013")).to eq("FC Dallas")
    end

    it "#fewest_tackles" do
      expect(@stat_tracker.fewest_tackles("20122013")).to eq("Sporting Kansas City")
    end

    it "#total_goals_by_teams" do
      expect(@stat_tracker.total_goals_by_teams).to eq({
        "3"   =>56,
        "6"   =>30,
        "5"   =>38,
        "17"  =>27,
        "16"  =>62,
        "9"   =>24,
        "8"   =>19,
        "30"  =>45,
        "26"  =>49,
        "19"  =>30,
        "24"  =>40,
        "2"   =>11,
        "15"  =>22,
        "20"  =>7,
        "14"  =>25,
        "28"  =>12,
        "4"   =>6,
        "21"  =>12,
        "25"  =>15
      })
    end

    it "#most_accurate_team" do
      expect(@stat_tracker.most_accurate_team("20122013")).to eq("LA Galaxy")
    end

    it "#least_accurate_team" do
      expect(@stat_tracker.least_accurate_team("20122013")).to eq("Sporting Kansas City")
    end

    it 'checks winningest coach' do
      expect(@stat_tracker.winningest_coach("20122013")).to eq("Claude Julien")
    end

    it 'checks worst coach' do
      expect(@stat_tracker.worst_coach("20122013")).to eq("John Tortorella")
    end
  end


  describe '#team_statistics' do
    it "#team_info" do
    expected = {
      "abbreviation"=>"ATL", 
      "franchise_id"=>"23", 
      "link"        =>"/api/v1/teams/1", 
      "team_id"     =>"1", 
      "team_name"   =>"Atlanta United"
    }
    expect(@stat_tracker.team_info("1")).to eq(expected)
    end

    it '#best_season' do
    expect(@stat_tracker.best_season("17")).to eq("20122013")
    end

    it '#worst_season' do
    expect(@stat_tracker.worst_season("17")).to eq("20132014")
    end

    it '#average_win_percentage' do
    expect(@stat_tracker.average_win_percentage("17")).to eq(0.56)
    end

    it '#most_goals_scored' do
    expect(@stat_tracker.most_goals_scored("17")).to eq(3)
    end

    it '#fewest_goals_scored' do
    expect(@stat_tracker.fewest_goals_scored("17")).to eq(1)
    end

    it '#rival' do
    expect(@stat_tracker.rival("17")).to eq("FC Dallas")
    end

    it '#favorite_opponent' do
    expect(@stat_tracker.favorite_opponent("17")).to eq("Seattle Sounders FC")
    end

    it '#head_to_head' do
    expected = {
      "16"=>0.5714, 
      "2"=>1.0
    }
    expect(@stat_tracker.head_to_head("17")).to eq(expected)
    end

    it '#worst_loss' do
    expect(@stat_tracker.worst_loss("17")).to eq(1)
    expect(@stat_tracker.worst_loss("16")).to eq(3)
    end

    it '#biggest_blowout' do
    expect(@stat_tracker.biggest_team_blowout("17")).to eq(3)
    expect(@stat_tracker.biggest_team_blowout("16")).to eq(1)
    end
  end

  describe 'helper methods' do
    it '#find_average' do
    smaller_hash = {
      a: 1,
      b: 2,
      c: 3
    }
    larger_hash = {
      a: 2,
      b: 3,
      c: 4
    }
    expected = {
      a: 0.5,
      b: 0.6667,
      c: 0.75
    }
    expect(@stat_tracker.find_average(smaller_hash, larger_hash)).to eq(expected)
    end

    it '#calc_percentage' do
    expect(@stat_tracker.calc_percentage(1, 2)).to eq(0.5)
    end

    it 'gives array of game_ids for a specific season' do
      expect(@stat_tracker.games_by_season("20162017")).to eq(["2016030151","2016030152", "2016030153","2016030154", "2016030111"])
    end

    it "#team_identifier" do
      
      id = "8"

      expect(@stat_tracker.team_identifier(id)).to eq("New York Red Bulls")
    end
  end
end