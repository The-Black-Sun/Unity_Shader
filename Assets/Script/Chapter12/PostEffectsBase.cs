using UnityEngine;
using System.Collections;

//编辑器状态下可以运行，查看效果，后处理效果绑定在某个摄像机上
[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class PostEffectsBase : MonoBehaviour {

	//检查各种资源条件是否满足后处理条件
	protected void CheckResources() {
		bool isSupported = CheckSupport();
		
		if (isSupported == false) {
			NotSupported();
		}
	}

	//检查是否支持后处理与渲染纹理
	protected bool CheckSupport() {
		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false) {
			Debug.LogWarning("This platform does not support image effects or render textures.");
			return false;
		}
		
		return true;
	}

	// Called when the platform doesn't support this effect
	protected void NotSupported() {
		//behaviour基类中的变量，用来判断能否更新
		enabled = false;
	}
	
	protected void Start() {
		CheckResources();
	}

	// 指向shader文件，并创建相对应的材质文件
	//shader是特效使用的shader,material是用于后期处理的材质
	protected Material CheckShaderAndCreateMaterial(Shader shader, Material material) {
		if (shader == null) {
			return null;
		}
		
		if (shader.isSupported && material && material.shader == shader)
			return material;
		
		if (!shader.isSupported) {
			return null;
		}
		else {
			material = new Material(shader);
			material.hideFlags = HideFlags.DontSave;
			if (material)
				return material;
			else 
				return null;
		}
	}
}
