using UnityEngine;
using System.Collections;

public class Bloom : PostEffectsBase {

	public Shader bloomShader;
	private Material bloomMaterial = null;
	public Material material {  
		get {
			bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
			return bloomMaterial;
		}  
	}

	//高斯模糊-迭代次数
	[Range(0, 4)]
	public int iterations = 3;
	
	//高斯模糊-范围
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;

	//高斯模糊-纹理存储缩放
	[Range(1, 8)]
	public int downSample = 2;

	//阈值，用来控制提取较亮区域时使用
	//大多数情况下，亮度不会超过1，如果开启了HDR，硬件会允许将颜色值存储在一个更高精度范围的缓冲中，此时亮度可能会超过1
	[Range(0.0f, 4.0f)]
	public float luminanceThreshold = 0.6f;

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			material.SetFloat("_LuminanceThreshold", luminanceThreshold);

			int rtW = src.width/downSample;
			int rtH = src.height/downSample;
			
			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear;
			
			//使用Shader中的第一个Pass提取图像中的较亮区域，存储在buffer0中
			Graphics.Blit(src, buffer0, material, 0);
			
			//进行高斯模糊迭代处理
			//对应Shader中的第二个和第三个Pass
			for (int i = 0; i < iterations; i++) {
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
				
				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
				
				// 第二个Pass进行滤波处理
				Graphics.Blit(buffer0, buffer1, material, 1);
				
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
				
				// 第三个Pass进行滤波处理
				Graphics.Blit(buffer0, buffer1, material, 2);
				
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			//设置模糊程度以及第四个Pass进行滤波处理,并显示图像
			material.SetTexture ("_Bloom", buffer0);  
			Graphics.Blit (src, dest, material, 3);  

			//释放缓存区
			RenderTexture.ReleaseTemporary(buffer0);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
