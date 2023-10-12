using UnityEngine;
using System.Collections;

//基础后处理基类
public class MotionBlurWithDepthTexture : PostEffectsBase {
	//Shader与材质声明
	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;
	//创建材质
	public Material material {  
		get {
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}  
	}

	//定义Camera类型的变量，获取该脚本所在的摄像机组件
	private Camera myCamera;
	public Camera camera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	//定义运动模糊是模糊图像使用的大小
	[Range(0.0f, 1.0f)]
	public float blurSize = 0.5f;

	//保存上一帧摄像机的视角*投影矩阵的变量
	private Matrix4x4 previousViewProjectionMatrix;
	
	void OnEnable() {
		//设置摄像机使用深度纹理
		camera.depthTextureMode |= DepthTextureMode.Depth;

		previousViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
	}
	
	//后处理的图形渲染
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			//计算与传递个Shader所需要的各个属性
			material.SetFloat("_BlurSize", blurSize);

			material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);

			//前一帧的视角*投影矩阵
			//worldToCameraMatrix 当前摄像机视角矩阵
			//projectionMatrix 当前投影矩阵
			Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
			
			//存储当前帧作为下一帧的上一帧使用
			Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
			material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
			previousViewProjectionMatrix = currentViewProjectionMatrix;

			//图像显示
			Graphics.Blit (src, dest, material);
		} else {
			//图像显示
			Graphics.Blit(src, dest);
		}
	}
}
