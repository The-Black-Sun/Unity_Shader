using UnityEngine;
using System.Collections;

public class MotionBlur : PostEffectsBase {

	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;

	public Material material {  
		get {
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}  
	}

	//定义运动模糊混合图像时使用的模糊参数
	[Range(0.0f, 0.9f)]
	public float blurAmount = 0.5f;
	
	//定义RenderTexture变量，保存之前的图像叠加效果
	private RenderTexture accumulationTexture;

	void OnDisable() {
		//销毁时释放缓存
		DestroyImmediate(accumulationTexture);
	}

	//运动模糊的效果实现
	//将当前的帧图像与accumulationTexture中的图像混合，
	//accumulationTexture中的纹理不需要提前清空，因为其中保存了之前的混合结果
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			// 首先判断用于混合图像的accumulationTexture是否符合条件，判空以及是否符合当前屏幕分辨率
			if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height) {
				//不符合则重新创建纹理，
				DestroyImmediate(accumulationTexture);
				accumulationTexture = new RenderTexture(src.width, src.height, 0);
				//并设置该变量内存不进行销毁（我们自己在OnDisable控制销毁），该变量不会显示在Hierarchy中，也不会保存在场景中，
				accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
				Graphics.Blit(src, accumulationTexture);
			}

            // Unity中提供的一个渲染纹理的恢复操作
			//恢复操作发生在渲染到纹理而该文李有没有被提前清空或销毁的情况下。
            accumulationTexture.MarkRestoreExpected();

			//传递混合模糊参数
			material.SetFloat("_BlurAmount", 1.0f - blurAmount);

			//将当前屏幕图像src叠加到accumulationTexture上，
			Graphics.Blit (src, accumulationTexture, material);
			//将叠加之后的图像效果在屏幕上显示
			Graphics.Blit (accumulationTexture, dest);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
