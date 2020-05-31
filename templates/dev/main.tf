terraform {
  required_version = ">= 0.12.0"

  backend "s3" {
    bucket  = "sample-app-state-dev" # 変数化したいけどできない仕様みたい、変数を取得する前にbackendは処理される
    region  = "ap-northeast-1"          # 変数化したいけどできない仕様みたい、変数を取得する前にbackendは処理される
    key     = "terraform.tfstate"
    encrypt = true
  }
}

