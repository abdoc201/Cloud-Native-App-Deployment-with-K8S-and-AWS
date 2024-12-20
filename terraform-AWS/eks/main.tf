terraform {
  backend "s3" {
    bucket = "terraform-state-abdo-2001"
    key    = "eks-terraform.tfstate"
    region = "eu-west-3"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_iam_role" "eks_iam_role" {
  name = "eks-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
    role = aws_iam_role.eks_iam_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  role = aws_iam_role.eks_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "eks_cluster" {
  name = "eks-cluster"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [var.PublicSubnet01_id,var.PublicSubnet02_id]
  }

  depends_on = [
    aws_iam_role.eks_iam_role,
  ]
}

resource "aws_iam_role" "workernodes" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name
}

resource "aws_eks_node_group" "worker_node_group" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  node_group_name = "worker-nodes"
  node_role_arn = aws_iam_role.workernodes.arn
  subnet_ids = [var.PublicSubnet01_id,var.PublicSubnet02_id]
  instance_types = ["t3.micro"]

  scaling_config {
    desired_size = 2
    max_size = 2
    min_size = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}
