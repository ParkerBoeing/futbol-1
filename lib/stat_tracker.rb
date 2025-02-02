require 'csv'
require_relative 'game'
require_relative 'team'
require_relative 'game_by_team'

class StatTracker

  attr_reader :games,
              :teams,
              :game_teams


  def initialize(files)
    @games = (CSV.open files[:games], headers: true, header_converters: :symbol).map do |row|
      Game.new(row)
    end
    @teams = (CSV.open files[:teams], headers: true, header_converters: :symbol).map do |row|
      Team.new(row)
    end
    @game_teams = (CSV.open files[:game_teams], headers: true, header_converters: :symbol).map do |row|
      GameTeam.new(row)
    end
  end

  def self.from_csv(files)
    StatTracker.new(files)
  end

#---------Game Statics Methods-----------
  def percentage_ties
    tie_count = @games.count { |game| game.away_goals.to_i == game.home_goals.to_i }
    calc_percentage(tie_count, @games.count)
  end

  def count_of_games_by_season
    season_games = @games.each_with_object(Hash.new(0)) {|game, hash| hash[game.season] += 1}
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
    away_wins = @games.find_all { |game| (game.away_goals.to_i > game.home_goals.to_i)}
    calc_percentage(away_wins.count, @games.count)
  end

  def average_goals_per_game
    total_goals = 0
    @games.each  {|game| total_goals += (game.away_goals.to_i + game.home_goals.to_i)}
    calc_percentage(total_goals, @games.count)
  end

  def percentage_home_wins
    home_wins = @games.find_all {|game| game.home_goals > game.away_goals}
    calc_percentage(home_wins.count, @games.count)
  end

  def average_goals_by_season
    goals_by_season = {}
    @games.each do |game|
      away = game.away_goals.to_i
      home = game.home_goals.to_i
      if goals_by_season.key?(game.season)
        goals_by_season[game.season] += (away + home)
      else
        goals_by_season[game.season] = away + home
      end
    end
    average_goals_by_s = {}
    goals_by_season.each {|key, value| average_goals_by_s[key] = calc_percentage(value, count_of_games_by_season[key])}
    average_goals_by_s
  end
#-------------- League Statics Methods --------
  def count_of_teams
    @teams.count
  end

  def best_offense
    average_goals_by_team
    highest_scoring_team = average_goals_by_team.max_by {|team, avg_goals| avg_goals}
    team_identifier(highest_scoring_team[0])
  end

  def worst_offense
    average_goals_by_team
    lowest_scoring_team = average_goals_by_team.min_by {|team, avg_goals| avg_goals}
    team_identifier(lowest_scoring_team[0])
  end

  def average_goals_by_team
    goals_scored = @game_teams.each_with_object(Hash.new(0)) {|game, team_hash| team_hash[game.team_id] += game.goals.to_i}
    games_played = @game_teams.each_with_object(Hash.new(0)) {|game, team_hash| team_hash[game.team_id] += 1}
    find_average(goals_scored, games_played)
  end

  def lowest_scoring_visitor
    goals_scored_as_visitor = @game_teams.each_with_object(Hash.new(0)) do |game, team_hash|
        team_hash[game.team_id] += game.goals.to_i if game.hoa == "away"
    end
    games_played_as_visitor = @game_teams.each_with_object(Hash.new(0)) do |game, team_hash|
        team_hash[game.team_id] += 1 if game.hoa == "away"
    end

    lowest_scoring_team = find_average(goals_scored_as_visitor, games_played_as_visitor).min_by {|team, avg_goals| avg_goals}
    @teams.each {|team| return lowest_scoring_team_name = team.team_name if team.team_id == lowest_scoring_team[0]}
    lowest_scoring_team_name

  end

  def lowest_scoring_home_team
    goals_scored_at_home = @game_teams.each_with_object(Hash.new(0)) do |game, team_hash|
        team_hash[game.team_id] += game.goals.to_i if game.hoa == "home"
    end
    games_played_at_home = @game_teams.each_with_object(Hash.new(0)) do |game, team_hash|
        team_hash[game.team_id] += 1 if game.hoa == "home"
    end
    lowest_scoring_team = find_average(goals_scored_at_home, games_played_at_home).min_by {|team, avg_goals| avg_goals}
    @teams.each {|team| return lowest_scoring_team_name = team.team_name if team.team_id == lowest_scoring_team[0]}
    lowest_scoring_team_name

  end

  def highest_scoring_visitor
    hoa_all_game_teams = @game_teams.group_by { |game_team| game_team.hoa }
    away_team_goals_hash = Hash.new { |hash, key| hash[key] = [] }
    hoa_all_game_teams.each do |hoa, game_team_array|
      game_team_array.each do |game_team|
        if hoa == "away"
          away_team_goals_hash[game_team.team_id] << game_team.goals.to_i
        end
      end
    end
    team_and_goal_avg = Hash.new { |hash, key| hash[key] = 0 }
    away_team_goals_hash.each do |team_id, goals_scored|
      avg_goals = (goals_scored.sum.to_f / goals_scored.length.to_f).round(6)
      team_and_goal_avg[team_id] = avg_goals
    end
    sorted_team_avg = team_and_goal_avg.sort_by { |_, value| value }
    id = sorted_team_avg.last.first
    team_identifier(id)
  end

  def highest_scoring_home_team
    hoa_all_game_teams = @game_teams.group_by { |game_team| game_team.hoa }
    home_team_goals_hash = Hash.new { |hash, key| hash[key] = [] }
    hoa_all_game_teams.each do |hoa, game_team_array|
      game_team_array.each do |game_team|
        if hoa == "home"
          home_team_goals_hash[game_team.team_id] << game_team.goals.to_i
        end
      end
    end
    team_and_goal_avg = Hash.new { |hash, key| hash[key] = 0 }
    home_team_goals_hash.each do |team_id, goals_scored|
      avg_goals = (goals_scored.sum.to_f / goals_scored.length.to_f).round(6)
      team_and_goal_avg[team_id] = avg_goals
    end
    sorted_team_avg = team_and_goal_avg.sort_by { |_, value| value }
    id = sorted_team_avg.last.first
    team_identifier(id)
  end

#-------------- Season Statics Methods --------

def most_tackles(season_id)
  tackles_by_team_season = Hash.new(0)

  games_by_season = []

  games_by_season_id = games_by_season(season_id)

  teams = []
  @game_teams.find_all do |game|
    teams << game.team_id if games_by_season_id.include?(game.game_id)
  end

  tackle_game = @game_teams.find_all { |game| games_by_season_id.include?(game.game_id) }
  tackle_game.each do |game|
    if tackles_by_team_season.key?(game.team_id)
      tackles_by_team_season[game.team_id] += game.tackles.to_i
    else
      tackles_by_team_season[game.team_id] = game.tackles.to_i
    end
  end
  most_tackles_id = tackles_by_team_season.max_by { |team_id, tackles| tackles }&.first
  team_identifier(most_tackles_id)
end

def fewest_tackles(season_id)
  tackles_by_team_season = Hash.new(0)
  games_by_season = []
  @games.each do |game|
    games_by_season << game.game_id if game.season == season_id
  end
  teams = []
  @game_teams.find_all do |game|
    teams << game.team_id if games_by_season.include?(game.game_id)
  end
  tackle_game = @game_teams.find_all { |game| games_by_season.include?(game.game_id) }
  tackle_game.each do |game|
    if tackles_by_team_season.key?(game.team_id)
      tackles_by_team_season[game.team_id] += game.tackles.to_i
    else
      tackles_by_team_season[game.team_id] = game.tackles.to_i
    end

    most_tackles_id = tackles_by_team_season.max_by { |team_id, tackles| tackles }&.first
    result = @teams.find { |team| team.team_id == most_tackles_id }
    result.team_name
  end
  fewest_tackles_id = tackles_by_team_season.min_by { |team_id, tackles| tackles }&.first
  team_identifier(fewest_tackles_id)
end

  def most_accurate_team(season_id)

    games_by_season = [] 

    games_by_season_id = games_by_season(season_id)

    team_stats = []
    game_teams.find_all { |game| team_stats << game if games_by_season_id.include?(game.game_id)}
    total_goals_per_team = team_stats.each_with_object(Hash.new(0)) do |game, team_hash|
      team_hash[game.team_id] += game.goals.to_i
  end
    total_shots_per_team = team_stats.each_with_object(Hash.new(0)) do |game, team_hash|
      team_hash[game.team_id] += game.shots.to_i
  end
  most_accurate_team = find_average(total_goals_per_team, total_shots_per_team).max_by {|team, avg_goals| avg_goals}
  most_accurate_team_name = nil
  team_identifier(most_accurate_team[0])
  end

  def least_accurate_team(season_id)

    games_by_season = [] 

    games_by_season_id = games_by_season(season_id)

    team_stats = []
    game_teams.find_all { |game| team_stats << game if games_by_season_id.include?(game.game_id)}
    total_goals_per_team = team_stats.each_with_object(Hash.new(0)) do |game, team_hash|
      team_hash[game.team_id] += game.goals.to_i
    end
    total_shots_per_team = team_stats.each_with_object(Hash.new(0)) do |game, team_hash|
      team_hash[game.team_id] += game.shots.to_i
    end
    least_accurate_team = find_average(total_goals_per_team, total_shots_per_team).min_by {|team, avg_goals| avg_goals}
    least_accurate_team_name = nil
    @teams.each { |team| least_accurate_team_name = team.team_name if team.team_id == least_accurate_team[0]}
    least_accurate_team_name

  end

  def total_goals_by_teams
    total_goals = {}
    @game_teams.each do |game|
      if total_goals.key?(game.team_id)
        total_goals[game.team_id] += game.goals.to_i
      else
        total_goals[game.team_id] = game.goals.to_i
      end
    end
    total_goals
  end

  def winningest_coach(season_id)
    games_by_season_id = games_by_season(season_id)

    coachs = []
    @game_teams.find_all do |game|
      coachs << game.head_coach if games_by_season_id.include?(game.game_id)
    end
    coachs.uniq.max_by do |coach|
      coach_wins = @game_teams.find_all {|game|  (game.head_coach == coach) && (game.result == "WIN") && (games_by_season_id.include?(game.game_id))}
      coach_games = @game_teams.find_all {|game| (game.head_coach == coach) && (games_by_season_id.include?(game.game_id))}
      calc_percentage(coach_wins.count, coach_games.count)
    end
  end

  def worst_coach(season_id)
    games_by_season_ids = []
    games_by_season_ids = games_by_season(season_id)
    coachs = []
    @game_teams.find_all do |game|
      coachs << game.head_coach if games_by_season_ids.include?(game.game_id)
    end
    coachs.uniq.min_by do |coach|

      coach_wins = @game_teams.find_all {|game|  (game.head_coach == coach) && (game.result == "WIN") && (games_by_season_ids.include?(game.game_id))}
      coach_games = @game_teams.find_all {|game| (game.head_coach == coach) && (games_by_season_ids.include?(game.game_id))}
      calc_percentage(coach_wins.count, coach_games.count)
    end
  end

  #-------------- Team Statics Methods ----------------

  def team_info(team_id)
    team = @teams.find { |team| team.team_id == team_id}
    team_info = {
      "team_id" => team.team_id,
      "franchise_id" => team.franchise_id,
      "team_name" => team.team_name,
      "abbreviation" => team.abbreviation,
      "link" => team.link
    }
    team_info
  end

  def best_season(team_id)
    games_played_by_team = [] 
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_played_by_team
    wins_by_season = games_played_by_team.each_with_object(Hash.new(0)) do |game, season_hash|
      if game.away_team_id == team_id && game.away_goals > game.home_goals
        season_hash[game.season] += 1
      elsif game.home_team_id == team_id && game.home_goals > game.away_goals
        season_hash[game.season] += 1
      else
      end
    end
    total_games_per_season = games_played_by_team.each_with_object(Hash.new(0)) do |game, season_hash|
      season_hash[game.season] += 1
    end
    best_season = find_average(wins_by_season, total_games_per_season).max_by {|season, win_percentage| win_percentage}
    best_season[0]
  end

  def worst_season(team_id)
    games_played_by_team = [] 
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_played_by_team
    wins_by_season = games_played_by_team.each_with_object(Hash.new(0)) do |game, season_hash|
      if game.away_team_id == team_id && game.away_goals > game.home_goals
        season_hash[game.season] += 1
      elsif game.home_team_id == team_id && game.home_goals > game.away_goals
        season_hash[game.season] += 1
      end
    end
    total_games_per_season = games_played_by_team.each_with_object(Hash.new(0)) do |game, season_hash|
      season_hash[game.season] += 1
    end
    worst_season = find_average(wins_by_season, total_games_per_season).min_by {|season, win_percentage| win_percentage}
    worst_season[0]
  end

  def average_win_percentage(team_id)
    games_played_by_team = [] 
    wins = 0
    games_played = 0
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_played_by_team.each do |game|
      if game.away_team_id == team_id && game.away_goals > game.home_goals
        wins += 1
        games_played += 1
      elsif game.home_team_id == team_id && game.home_goals > game.away_goals
        wins += 1
        games_played += 1
      else
        games_played += 1
      end

    end
    calc_percentage(wins, games_played)
  end

  def most_goals_scored(team_id)
    games_played_by_team = [] 
    most_away_goals = 0
    most_home_goals = 0
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_played_by_team.each do |game|
      if game.away_team_id == team_id && game.away_goals.to_i > most_away_goals
        most_away_goals = game.away_goals.to_i
      elsif game.home_team_id == team_id && game.home_goals.to_i > most_home_goals
        most_home_goals = game.home_goals.to_i
      else
      end
    end
    most_home_goals > most_away_goals ? most_home_goals : most_away_goals
  end

  def fewest_goals_scored(team_id)
    games_played_by_team = [] 
    fewest_away_goals = Float::INFINITY
    fewest_home_goals = Float::INFINITY
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_played_by_team.each do |game|
      if game.away_team_id == team_id && game.away_goals.to_i < fewest_away_goals
        fewest_away_goals = game.away_goals.to_i
      elsif game.home_team_id == team_id && game.home_goals.to_i < fewest_home_goals
        fewest_home_goals = game.home_goals.to_i
      else
      end
    end
    fewest_home_goals < fewest_away_goals ? fewest_home_goals : fewest_away_goals
  end

  def rival(team_id)
    games_played_by_team = [] 
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_against_opponents = games_played_by_team.each_with_object(Hash.new(0)) do |game, rival_hash|
      if team_id == game.away_team_id
        rival_hash[game.home_team_id] += 1
      elsif team_id == game.home_team_id
        rival_hash[game.away_team_id] += 1
      else
      end
    end
    losses_against_opponents = games_played_by_team.each_with_object(Hash.new(0)) do |game, rival_hash|
      if team_id == game.away_team_id && game.away_goals < game.home_goals
        rival_hash[game.home_team_id] += 1
      elsif team_id == game.home_team_id && game.home_goals < game.away_goals
        rival_hash[game.away_team_id] += 1
      else
      end
    end
    rival = find_average(losses_against_opponents, games_against_opponents).max_by {|season, win_percentage| win_percentage}
    rival[0]
    rival_team_name = nil
    @teams.each { |team| rival_team_name = team.team_name if team.team_id == rival[0]}
    rival_team_name
  end

  def favorite_opponent(team_id)
    games_played_by_team = [] 
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_against_opponents = games_played_by_team.each_with_object(Hash.new(0)) do |game, favorite_opponent_hash|
      if team_id == game.away_team_id
        favorite_opponent_hash[game.home_team_id] += 1
      elsif team_id == game.home_team_id
        favorite_opponent_hash[game.away_team_id] += 1
      else
      end
    end
    wins_against_opponents = games_played_by_team.each_with_object(Hash.new(0)) do |game, favorite_opponent_hash|
      if team_id == game.away_team_id && game.away_goals > game.home_goals
        favorite_opponent_hash[game.home_team_id] += 1
      elsif team_id == game.home_team_id && game.home_goals > game.away_goals
        favorite_opponent_hash[game.away_team_id] += 1
      else
      end
    end
    favorite_opponent = find_average(wins_against_opponents, games_against_opponents).max_by {|season, win_percentage| win_percentage}
    favorite_opponent[0]
    favorite_opponent_team_name = nil
    @teams.each { |team| favorite_opponent_team_name = team.team_name if team.team_id == favorite_opponent[0]}
    favorite_opponent_team_name
  end

  def head_to_head(team_id)
    games_played_by_team = [] 
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_against_opponents = games_played_by_team.each_with_object(Hash.new(0)) do |game, favorite_opponent_hash|
      if team_id == game.away_team_id
        favorite_opponent_hash[game.home_team_id] += 1
      elsif team_id == game.home_team_id
        favorite_opponent_hash[game.away_team_id] += 1
      else
      end
    end
    wins_against_opponents = games_played_by_team.each_with_object(Hash.new(0)) do |game, favorite_opponent_hash|
      if team_id == game.away_team_id && game.away_goals > game.home_goals
        favorite_opponent_hash[game.home_team_id] += 1
      elsif team_id == game.home_team_id && game.home_goals > game.away_goals
        favorite_opponent_hash[game.away_team_id] += 1
      else
      end
    end
    average_win_percentage = find_average(wins_against_opponents, games_against_opponents)
    average_win_percentage
  end

  def worst_loss(team_id)
    worst_loss = 0
    difference = 0
    games_played_by_team = [] 
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_played_by_team.each do |game|
      if team_id == game.away_team_id && game.away_goals.to_i < game.home_goals.to_i
        difference = game.home_goals.to_i - game.away_goals.to_i
      elsif team_id == game.home_team_id && game.home_goals.to_i < game.away_goals.to_i
        difference = game.away_goals.to_i - game.home_goals.to_i
      else
      end
      worst_loss = difference if difference > worst_loss
    end
    worst_loss
  end

  def biggest_team_blowout(team_id)
    biggest_blowout = 0
    difference = 0
    games_played_by_team = [] 
    @games.each { |game| games_played_by_team << game if game.away_team_id == team_id || game.home_team_id == team_id}
    games_played_by_team.each do |game|
      if team_id == game.away_team_id && game.away_goals.to_i > game.home_goals.to_i
        difference = game.away_goals.to_i - game.home_goals.to_i
      elsif team_id == game.home_team_id && game.home_goals.to_i > game.away_goals.to_i
        difference = game.home_goals.to_i - game.away_goals.to_i
      else
      end
      biggest_blowout = difference if difference > biggest_blowout
    end
    biggest_blowout
  end

  #------------------------------Helper Methods---------------------------------

  def find_average(smaller_hash, larger_hash)
    average = Hash.new(0)
    smaller_hash.each do |key1, value1|
      larger_hash.each do |key2, value2|
        average[key1] = value1.to_f / value2.to_f if key1 == key2
      end
    end
    average.each { |key, value| average[key] = value.round(4) }
    average
  end

  def calc_percentage(val1, val2)
    (val1.to_f / val2.to_f).round(2)
  end

  def games_by_season(season_id)
    game_ids = []
    @games.each do |game|
      game_ids << game.game_id if (game.season == season_id)
    end
    game_ids
  end
    
  def team_identifier(team_id)
    result = @teams.find { |team| team.team_id == team_id }
    result.team_name
  end
end



