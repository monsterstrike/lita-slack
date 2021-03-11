module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class UserCreator
        class << self
          def create_user(slack_user, robot, robot_id)
            metadata = {
                name: real_name(slack_user),
                mention_name: slack_user.name,
            }

            is_bot = slack_user.raw_data["is_bot"]
            metadata.merge!(is_bot: is_bot)

            User.create(
              slack_user.id,
              metadata
            )

            update_robot(robot, slack_user) if slack_user.id == robot_id
            robot.trigger(:slack_user_created, slack_user: slack_user)
          end

          def create_from_api(slack_user, robot, robot_id, api)
            Lita.logger.debug("called UserCreator#create_from_api #{slack_user}")
            user = api.users_profile_get(slack_user)
            create_user(SlackUser.from_data(user), robot, robot_id)
            lita_user = User.find_by_id(slack_user)
            lita_user
          end

          def create_users(slack_users, robot, robot_id)
            slack_users.each { |slack_user| create_user(slack_user, robot, robot_id) }
          end

          private

          def real_name(slack_user)
            slack_user.real_name.size > 0 ? slack_user.real_name : slack_user.name
          end

          def update_robot(robot, slack_user)
            robot.name = slack_user.real_name
            robot.mention_name = slack_user.name
          end
        end
      end
    end
  end
end
