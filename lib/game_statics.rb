class GameStatics

    def initialize(game_object_array)
        @games = game_object_array
    end

    def highest_total_score
        highest_score = 0

        @games.each do |game|
        total_score = game["home_goals"].to_i + game["away_goals"].to_i
        highest_score = total_score if total_score > highest_score
        end
        highest_score
    end

    def lowest_total_score
        lowest_score = nil

        @games.each do |game|
            total_score = game["home_goals"].to_i + game["away_goals"].to_i
            lowest_score = total_score if lowest_score.nil? || total_score < lowest_score
        end
        lowest_score
    end

    def percentage_visitor_wins(games_array)
        away_wins = games_array.find_all do |game|
            (game.hoa == "away") && (game.result == "WIN")
        end
        ((away_wins.count.to_f / games_array.count.to_f) * 100).ceil(2)
    end

    def average_goals_per_game(games_array)
        total_goals = 0
        games_array.each do |game|
            total_goals += (game.away_goals.to_i + game.home_goals.to_i)
        end
        (total_goals.to_f / games_array.count.to_f).ceil(2)
    end
end