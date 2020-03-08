# frozen_string_literal: true

module RoctoCop
  module Actions
    module Linter
      class FixAll
        class << self
          def action_definition
            {
              label: 'Fix all these',
              description: 'Fix all Roctocop Linter notices for me.',
              identifier: 'fix_roctocop_linter'
            }
          end
        end

        attr_reader :client, :repo, :branch, :run_id

        def initialize(client, repo, branch, run_id)
          @client = client
          @repo   = repo
          @branch = branch
          @run_id = run_id
        end

        def run
          inside_local_repo do |local_repo|
            local_repo.config('user.name', 'Roctocop Linter')
            local_repo.config('user.email', 'linter@roctocop.io')
            `rubocop ./* --format json --auto-correct`
            local_repo.commit_all('Automatic resolution of Roctocop Linter notices')
            local_repo.push(repo_url, branch)
          end
        ensure
          FileUtils.remove_entry(tmpdir, true)
        end

        private

        def inside_local_repo
          r = Git.clone(repo_url, tmpdir)
          r.chdir do
            r.pull
            r.checkout(branch)
            yield r
          end
        end

        def repo_url
          @repo_url ||= "https://x-access-token:#{client.bearer_token}@github.com/#{repo}.git"
        end

        def tmpdir
          @tmpdir ||= File.expand_path(run_id.to_s, Dir.tmpdir)
        end
      end
    end
  end
end
