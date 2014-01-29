class CreateProjectService
  include Rails.application.routes.url_helpers

  def execute(current_user, params, project_route)
    @project = Project.parse(params)

    Project.transaction do
      # Send emails only on broken builds be default
      @project.email_all_broken_builds = true

      # Disable committer notification by defualt to prevent spamming
      @project.email_add_committer = false

      @project.save!

      opts = {
        token: @project.token,
        project_url: project_route.gsub(":project_id", @project.id.to_s),
      }

      if Network.new.enable_ci(current_user.url, @project.gitlab_id, opts, current_user.private_token)
        true
      else
        raise ActiveRecord::Rollback
      end
    end

    @project
  end
end
