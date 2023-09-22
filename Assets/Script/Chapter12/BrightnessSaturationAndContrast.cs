using UnityEngine;
using System.Collections;

//继承基类
public class BrightnessSaturationAndContrast : PostEffectsBase {

	//声明Shader并创建材质
	public Shader briSatConShader;
	private Material briSatConMaterial;
	public Material material {  
		get {
			briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
			return briSatConMaterial;
		}  
	}

	//亮度、饱和度、对比度参数
	[Range(0.0f, 3.0f)]
	public float brightness = 1.0f;

	[Range(0.0f, 3.0f)]
	public float saturation = 1.0f;

	[Range(0.0f, 3.0f)]
	public float contrast = 1.0f;

	//设置渲染纹理的特效
	void OnRenderImage(RenderTexture src, RenderTexture dest) {
		if (material != null) {
			//设置纹理的亮度，饱和度、对比度
			material.SetFloat("_Brightness", brightness);
			material.SetFloat("_Saturation", saturation);
			material.SetFloat("_Contrast", contrast);

			Graphics.Blit(src, dest, material);
		} else {
			//直接将原图像显示到屏幕上，不处理
			Graphics.Blit(src, dest);
		}
	}
}
