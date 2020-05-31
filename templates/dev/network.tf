#ネットワーク初期設定

#まず全ての入れ物を作る（アドレスの範囲を設定 ※あとから変更できない）
resource "aws_vpc" "vpc" {
  #IPアドレスの範囲指定 vpcは/16が適当でサイズが一番大きい
  cidr_block = "10.0.0.0/16"
  #名前解決を有効
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.service_name}_vpc_${var.stage}"
  }
}

#次に小分け袋を作る（Network ACLにより、どこと通信できるか設定）
#インターネット通信ができるサブネットをpublicとして扱う
#システムをセキュアに保つためにpublicには必要最小限のリソースのみ配置する
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "${var.service_name}_public_a_subnet_${var.stage}"
  }
}
#cidrの値をAZ毎に変える
resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "${var.service_name}_public_c_subnet_${var.stage}"
  }
}

#インターネット通信するためにはinternet_gatewayをVPCに設定。
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.service_name}_${var.stage}"
  }
}

#internet_gatewayだけではまだインターネットと通信できず、ルートテーブルが必要
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.service_name}_${var.stage}"
  }
}

#VPC以外への通信を、internet_gateway経由でインターネットへデータを流すために、デフォルトルート(0.0.0.0/0)を設定
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.internet_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

#どのルートテーブルを使ってルーティングするかをサブネット単位て設定する
#ここでサブネットがインターネット通信できる
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

#インターネットから隔離されたネットワーク、DBサーバなどを設置する
#サブネットでCIDRが被らないようにする必要がある
#インターネット通信をしないのでpublic_ipはオフ、インタネットゲートウェイとの紐付けもなし
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.service_name}_private_a_subnet_${var.stage}"
  }
}

#cidrの値をAZ毎に変える
resource "aws_subnet" "private_c" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.service_name}_private_c_subnet_${var.stage}"
  }
}

#natでプライベートネットワークからインターネットへアクセスできる
#natゲートウェイに関連付ける Elastic IP アドレスも、ゲートウェイの作成時に指定する必要がある。
//resource "aws_eip" "nat_gateway_a" {
//  vpc        = true
//  depends_on = [aws_internet_gateway.internet_gateway]
//}
//
//#subnet_idはnatの設置場所 インターネット接続できるようにするため、publicに設置
//#privateではないので注意
//resource "aws_nat_gateway" "nat_gateway_a" {
//  allocation_id = aws_eip.nat_gateway_a.id
//  subnet_id     = aws_subnet.public_a.id
//  depends_on    = [aws_internet_gateway.internet_gateway]
//}
//
//#ルートテーブル
//resource "aws_route_table" "private_a" {
//  vpc_id = aws_vpc.vpc.id
//}
//
//#インターネット通信を行うために、natとルートテーブルで紐付け
//resource "aws_route" "private_a" {
//  route_table_id         = aws_route_table.private_a.id
//  nat_gateway_id         = aws_nat_gateway.nat_gateway_a.id
//  destination_cidr_block = "0.0.0.0/0"
//}
//
//#ルートテーブルとサブネットの紐付け 設定は問題ないとように感じるがうまくいっていない手動でprivate_aのルートテーブルを紐付け
//resource "aws_route_table_association" "private_a" {
//  subnet_id      = aws_subnet.private_a.id
//  route_table_id = aws_route_table.private_a.id
//}
//
//resource "aws_route_table_association" "private_c" {
//  subnet_id      = aws_subnet.private_c.id
//  route_table_id = aws_route_table.private_a.id
//}

