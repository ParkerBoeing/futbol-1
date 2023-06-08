require 'csv'
require './lib/game'
require './lib/team'
require './lib/game_by_team'

class StatTracker

  attr_reader :games,
              :teams,
              :game_by_team
  def initialize
    @games = []
    @teams = []
    @game_by_team = []
  end

  def from_csv(locations_hash)
    CSV.foreach(locations_hash[:games], headers: true, header_converters: :symbol) do |row|
      @games << Game.new(row)
    end
    CSV.foreach(locations_hash[:teams], headers: true, header_converters: :symbol) do |row|
      @teams << Team.new(row)
    end
    CSV.foreach(locations_hash[:game_by_team], headers: true, header_converters: :symbol) do |row|
      @game_by_team << Game_By_Team.new(row)
    end
  end
      
#---------Game Statics Methods-----------
  def percentage_ties
    tie_count = @games.count { |game| game.away_goals.to_i == game.home_goals.to_i }
    percentage = (tie_count.to_f / @games.count.to_f).round(4) * 100
    p percentage
  end

  def count_of_games_by_season
  season_games = @games.each_with_object(Hash.new(0)) {|game, hash| hash[game.season] += 1}
  p season_games
  end

  def highest_total_score
    highest_score = 0
    @games.each do |game|
      total_score = game.home_goals.to_i + game.away_goals.to_i
      highest_score = total_score if total_score > highest_score
    end
    highest_score
  end

  def lowest_total_score
    lowest_score = nil
    @games.each do |game|
      total_score = game.home_goals.to_i + game.away_goals.to_i
      lowest_score = total_score if lowest_score.nil? || total_score < lowest_score
    end
    lowest_score
  end

  def percentage_visitor_wins
    away_wins = @game_by_team.find_all do |game|
      (game.hoa == "away") && (game.result == "WIN")
    end
    ((away_wins.count.to_f / @game_by_team.count.to_f) * 100).ceil(2)
  end

  def average_goals_per_game
    total_goals = 0
    @games.each do |game|
      total_goals += (game.away_goals.to_i + game.home_goals.to_i)
    end
    (total_goals.to_f / @games.count.to_f).ceil(2)
  end

  def percentage_home_wins
    home_wins = @games.find_all do |game|
      game.home_goals > game.away_goals
    end
    @games.count * home_wins.count / 100.to_f
  end

#-------------- League Statics Methods --------
  def best_offense
    goals_scored = @game_by_team.each_with_object(Hash.new(0)) {|game, team_hash| team_hash[game.team_id] += game.goals.to_i}
    games_played = @game_by_team.each_with_object(Hash.new(0)) {|game, team_hash| team_hash[game.team_id] += 1}
    average_goals_per_game = Hash.new(0)
    goals_scored.each do |key1, value1|
      games_played.each do |key2, value2|
        if key1 == key2
          average_goals_per_game[key1] = value1.to_f / value2.to_f
        else
        end
      end
    end
  highest_scoring_team = average_goals_per_game.max_by {|team, avg_goals| avg_goals}
  highest_scoring_team_name = nil
  @teams.each do |team|
    if team.team_id == highest_scoring_team
      highest_scoring_team_name = team.team_name
    else
    end
    end
  highest_scoring_team_name
  end

  def worst_offense
    @game_by_team
  end

  def lowest_scoring_visitor

  end

  def lowest_scoring_home_team

  end
#-------------- Season Statics Methods --------
end