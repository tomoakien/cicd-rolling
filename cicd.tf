#code build作成
#ver1のgithub tokenが非推奨の為、使用しない。
#認証はpipelineで行い、通ってからcode buildが動く。

resource "aws_codebuild_project" "codebuild" {
  name         = "ctn-cicd-build"
  description  = "Codebuild project"
  service_role = aws_iam_role.codebuild_role.arn
  #ここのブロックでどこのソースを使用するか決める
  source {
    type            = "GITHUB"
    location        = var.github_repository
    git_clone_depth = 0
    buildspec = templatefile("${path.module}/buildspec.tpl", {
      AWS_DEFAULT_REGION = "ap-northeast-1"
    })
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    #imageの指定をする事でbuildをamazon linuxかubuntuにするか決定する。
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    #dockerをビルドする為必須
  }
  build_timeout = 60
}

# --------------------------------
# code pipeline作成

resource "aws_codepipeline" "pipeline" {
  name     = "ctn-cicd-pipeline"
  role_arn = aws_iam_role.aws_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }

  #ソースステージ：Githubからソースを取得
  #トリガとしてGithubやCodeCommitのソースリポジトリを設定する。
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = var.github_full_repository_name
        BranchName           = "main"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.cluster.name
        ServiceName = aws_ecs_service.service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}
