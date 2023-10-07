using UnityEngine;
using System.Collections;

public class GaussianBlur : PostEffectsBase {

	public Shader gaussianBlurShader;
	private Material gaussianBlurMaterial = null;

	public Material material {  
		get {
			gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
			return gaussianBlurMaterial;
		}  
	}

	// Blur iterations - larger number means more blur.
	// 高斯模糊迭代次数
	[Range(0, 4)]
	public int iterations = 3;
	
	// Blur spread for each iteration - larger value means more blur
	// 模糊范围
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;
	
	//缩放系数
	[Range(1, 8)]
	public int downSample = 2;

	/// 1st edition: just apply blur
	/// 最简单的OnRenderImage实现
	//	void OnRenderImage(RenderTexture src, RenderTexture dest) {
	//		if (material != null) {
	//			int rtW = src.width;
	//			int rtH = src.height;
	//			//利用RenderTexture.GetTemporary函数分配了一块与屏幕图像大小相同的缓冲区
	//			//这是因为使用了两个Pass，所以需要有缓冲区保存第一个Pass的执行结果
	//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
	//
	//			// Render the vertical pass
	//			// 使用Shader的第一个Pass（竖直方向的一维高斯核进行滤波）对src进行处理，并存储在buffer中
	//			Graphics.Blit(src, buffer, material, 0);
	//			// Render the horizontal pass
	//			// 使用第二个Pass进行滤波处理，并返回最终图像
	//			Graphics.Blit(buffer, dest, material, 1);
	//
	//			//使用RenderTexture.ReleaseTemporary来释放之前分配的缓存
	//			RenderTexture.ReleaseTemporary(buffer);
	//		} else {
	//			Graphics.Blit(src, dest);
	//		}
	//	} 

	/// 2nd edition: scale the render texture
	/// 利用缩放对图像进行降采样，从而减少需要处理的像素个数，提高性能
	//	void OnRenderImage (RenderTexture src, RenderTexture dest) {
	//		if (material != null) {
	//			//对将要申请的缓存区大小进行了缩小（2倍）
	//			int rtW = src.width/downSample;
	//			int rtH = src.height/downSample;
	//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
	//			//滤波模式设置成了双线性
	//			buffer.filterMode = FilterMode.Bilinear;
	//
	//			// Render the vertical pass
	//			Graphics.Blit(src, buffer, material, 0);
	//			// Render the horizontal pass
	//			Graphics.Blit(buffer, dest, material, 1);
	//			//释放缓存区
	//			RenderTexture.ReleaseTemporary(buffer);
	//		} else {
	//			Graphics.Blit(src, dest);
	//		}
	//	}

	/// 3rd edition: use iterations for larger blur
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			//缩小需要进行缓存的纹理大小
			int rtW = src.width/downSample;
			int rtH = src.height/downSample;
			//申请第一个缓存区buffer0
			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			//滤波模式设置成了双线性
			buffer0.filterMode = FilterMode.Bilinear;

			//将图像存储到Buffer0中
			Graphics.Blit(src, buffer0);

			//根据迭代次数进行高斯迭代
			for (int i = 0; i < iterations; i++) {
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
				//申请缓存区buffer1
				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// 进行第一次高斯模糊的滤波处理，并存储到buffer1中
				Graphics.Blit(buffer0, buffer1, material, 0);
				// 释放缓存区buffer0 
				RenderTexture.ReleaseTemporary(buffer0);

				//缓存区互换，并申请新的缓存区
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				//进行第二次滤波处理
				Graphics.Blit(buffer0, buffer1, material, 1);

				//释放缓存区buffer0，并将缓存区内图像存储到buffer0中
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			//将图像进行显示，并释放缓冲区
			Graphics.Blit(buffer0, dest);
			RenderTexture.ReleaseTemporary(buffer0);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
