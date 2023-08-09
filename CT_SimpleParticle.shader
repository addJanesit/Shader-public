Shader "BountyBrawl/Particle/CT_SimpleParticle"
{
	Properties
	{
		[KeywordEnum(Off,Front,Back)] _RenderType("Cull Face", Float) = 0
		[Header(Render Mode)][Space(2)]
		[KeywordEnum(CommonTransparent,Additive,MildAdditive,Multiply,MultiplyX2,Overlay,SoftLight,Negative)] _BlendingMode("Blend Mode", Float) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("SrcFactor", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("DstFactor", Float) = 10
		[Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("ZTest", Float) = 4

		[HDR]_TintColor("Tint Color", Color) = (1,1,1,1)
		[KeywordEnum(R,G,B,Normal)] _TextureChannel("Texture Channel", Float) = 0
		_MainTex("Particle Texture", 2D) = "white" {}

		[Header(Panner and Rotator)][Space(2)]
		[KeywordEnum(Off,Panner,Rotator)]_TexCoordFeature("Use TexCoord Feature", Float) = 0
		[Header(UV Panner)][Space(3)]
		_PannerSpeedX("Panner Speed X", Float) = 0
		_PannerSpeedY("Panner Speed Y", Float) = 0
		[Header(UV Rotator)]
		_rotateSpeed("Rotation Speed", Float) = 0

		[Space(10)][KeywordEnum(Off,Voronoid,Texture)] _NoiseFeature("Use Noise", Float) = 0
		[KeywordEnum(R,G,B,Normal)] _MaskNoiseTextureChannel("Mask Channel", Float) = 0
		[NoScaleOffset]_UVNoiseShaderMask("Mask", 2D) = "white" {}
		[Header(Voronoid Noise)][Space(2)]
		_noiseSpeed("Voronoid Speed", Float) = 6
		_noiseScale("Voronoid Scale", Float) = 2.5
		_PowerScale("Voronoid Power", Float) = 0.7
		[Header(Texture Noise)][Space(2)]
		_PannerNoiseSpeedX("NoisePanner Speed X", Float) = 0
		_PannerNoiseSpeedY("NoisePanner Speed Y", Float) = 0
		[KeywordEnum(R,G,B,Normal)] _NoiseTextureChannel("Noise Channel", Float) = 0
		_CustomNoiseTexture("Noise Texture", 2D) = "white" {}

		[Space(10)][Toggle(_USEDISTORT_ON)] _UseDistort("Use Distort", Float) = 0
		[KeywordEnum(R,G,B)] _DistortTextureChannel("Distort Channel", Float) = 0
		_NoiseTexture("Distort Texture", 2D) = "white" {}
		[KeywordEnum(R,G,B,Normal)] _MaskDistortTextureChannel("Mask Channel", Float) = 0
		[NoScaleOffset]_UVDistortShaderMask("Mask", 2D) = "white" {}
		_UVDistortFade("Fade", Range(0 , 1)) = 1
		_UVDistortFrom("From", Vector) = (-0.02,-0.02,0,0)
		_UVDistortTo("To", Vector) = (0.02,0.02,0,0)
		_UVDistortSpeed("Speed", Vector) = (2,2,0,0)
		_UVDistortNoiseScale("Scale", Vector) = (0.1,0.1,0,0)

		_InvFade("Soft Particles Factor", Range(0.01,3.0)) = 1.0
		
	}


		Category
		{
			SubShader
			{
			LOD 0
				Tags { "Queue" = "Transparent+2" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
				Blend[_SrcBlend][_DstBlend]
				ColorMask RGB
				Cull[_RenderType]
				Lighting Off
				ZWrite Off
				ZTest[_ZTest]

				Pass {

					CGPROGRAM

					#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
					#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
					#endif

					#pragma vertex vert
					#pragma fragment frag
					#pragma target 2.0
					#pragma multi_compile_instancing
					#pragma multi_compile_particles
					#pragma multi_compile_fog

					#pragma shader_feature _TEXTURECHANNEL_R _TEXTURECHANNEL_G _TEXTURECHANNEL_B _TEXTURECHANNEL_NORMAL
					#pragma shader_feature _TEXCOORDFEATURE_OFF _TEXCOORDFEATURE_PANNER _TEXCOORDFEATURE_ROTATOR
					#pragma shader_feature _USEDISTORT_ON
					#pragma shader_feature _NOISEFEATURE_OFF _NOISEFEATURE_VORONOID _NOISEFEATURE_TEXTURE
					#pragma shader_feature _NOISETEXTURECHANNEL_R _NOISETEXTURECHANNEL_G _NOISETEXTURECHANNEL_B _NOISETEXTURECHANNEL_NORMAL
					#pragma shader_feature _MASKNOISETEXTURECHANNEL_R _MASKNOISETEXTURECHANNEL_G _MASKNOISETEXTURECHANNEL_B _MASKNOISETEXTURECHANNEL_NORMAL
					#pragma shader_feature _DISTORTTEXTURECHANNEL_R _DISTORTTEXTURECHANNEL_G _DISTORTTEXTURECHANNEL_B
					#pragma shader_feature _MASKDISTORTTEXTURECHANNEL_R _MASKDISTORTTEXTURECHANNEL_G _MASKDISTORTTEXTURECHANNEL_B _MASKDISTORTTEXTURECHANNEL_NORMAL

					#include "UnityCG.cginc"

					struct vertexInput
					{
						float4 vertex : POSITION;
						fixed4 vertexColor : COLOR;
						float2 texcoord : TEXCOORD0;
						UNITY_VERTEX_INPUT_INSTANCE_ID
					};

					struct vertexOutput
					{
						float4 vertex : SV_POSITION;
						fixed4 vertexColor : COLOR;
						float2 texcoord : TEXCOORD0;
						UNITY_FOG_COORDS(1)
						#ifdef SOFTPARTICLES_ON
						float4 projPos : TEXCOORD2;
						#endif
						UNITY_VERTEX_INPUT_INSTANCE_ID
						UNITY_VERTEX_OUTPUT_STEREO

					};


					#if UNITY_VERSION >= 560
					UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
					#else
					uniform sampler2D_float _CameraDepthTexture;
					#endif

					//Don't delete this comment
					// uniform sampler2D_float _CameraDepthTexture;

					uniform sampler2D _MainTex;
					uniform fixed4 _TintColor;
					uniform float4 _MainTex_ST;
					uniform float _InvFade;


					#if _TEXCOORDFEATURE_PANNER
						uniform float _PannerSpeedX;
						uniform float _PannerSpeedY;
					#elif _TEXCOORDFEATURE_ROTATOR
						uniform float _rotateSpeed;
					#endif

					#if _NOISEFEATURE_VORONOID
						uniform float _noiseSpeed;
						uniform float _noiseScale;
						uniform float _PowerScale;
						uniform sampler2D _UVNoiseShaderMask;
						uniform float4 _UVNoiseShaderMask_ST;
					#endif

					#if _NOISEFEATURE_TEXTURE
						uniform float _PannerNoiseSpeedX;
						uniform float _PannerNoiseSpeedY;
						uniform sampler2D _CustomNoiseTexture;
						uniform float4 _CustomNoiseTexture_ST;
						uniform sampler2D _UVNoiseShaderMask;
						uniform float4 _UVNoiseShaderMask_ST;
					#endif



					#if _USEDISTORT_ON
						uniform float4 _MainTex_TexelSize;
						uniform sampler2D _NoiseTexture;
						uniform float _UVDistortFade;
						uniform sampler2D _UVDistortShaderMask;
						uniform float4 _UVDistortShaderMask_ST;
						uniform float2 _UVDistortFrom;
						uniform float2 _UVDistortTo;
						uniform float2 _UVDistortSpeed;
						uniform float2 _UVDistortNoiseScale;
					#endif

					float2 TexcoordRotator(float2 uv, float rotSpeed)
					{
						float2 rotateValue;
						float2 Anchor = float2(0.5, 0.5);
						float cosRot = cos((rotSpeed * _Time.y));
						float sinRot = sin((rotSpeed * _Time.y));
						float2x2 rotationMatrix = float2x2(cosRot, -sinRot, sinRot, cosRot);

						rotateValue = mul(uv - Anchor, rotationMatrix) + Anchor;

						return rotateValue;
					}

					float2 TexcoordPanner(float2 uv, float speedX, float speedY)
					{
						float2 pannerSpeed = float2(speedX, speedY);
						float2 pannerValue = (_Time.y * pannerSpeed + uv);
						return pannerValue;
					}

					inline float2 UnityVoronoiRandomVector(float2 UV, float offset)
					{
						float2x2 m = float2x2(15.27, 47.63, 99.41, 89.98);
						UV = frac(sin(mul(UV, m)) * 46839.32);
						return float2(sin(UV.y * +offset) * 0.5 + 0.5, cos(UV.x * offset) * 0.5 + 0.5);
					}

					//x - Out y - Cells
					float3 UnityVoronoi(float2 UV, float AngleOffset, float CellDensity, inout float2 mr)
					{
						float2 g = floor(UV * CellDensity);
						float2 f = frac(UV * CellDensity);
						float t = 8.0;
						float3 res = float3(8.0, 0.0, 0.0);

						for (int y = -1; y <= 1; y++)
						{
							for (int x = -1; x <= 1; x++)
							{
								float2 lattice = float2(x, y);
								float2 offset = UnityVoronoiRandomVector(lattice + g, AngleOffset);
								float d = distance(lattice + offset, f);

								if (d < res.x)
								{
									mr = f - lattice - offset;
									res = float3(d, offset.x, offset.y);
								}
							}
						}
						return res;
					}

					vertexOutput vert(vertexInput v)
					{
						vertexOutput o;
						UNITY_SETUP_INSTANCE_ID(v);
						UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
						UNITY_TRANSFER_INSTANCE_ID(v, o);


						v.vertex.xyz += float3(0, 0, 0);
						o.vertex = UnityObjectToClipPos(v.vertex);
						#ifdef SOFTPARTICLES_ON
							o.projPos = ComputeScreenPos(o.vertex);
							COMPUTE_EYEDEPTH(o.projPos.z);
						#endif
						o.vertexColor = v.vertexColor;
						o.texcoord = v.texcoord;

						#if _TEXCOORDFEATURE_PANNER	
							o.texcoord = TexcoordPanner(v.texcoord, _PannerSpeedX, _PannerSpeedY);
#						elif _TEXCOORDFEATURE_ROTATOR
							o.texcoord = TexcoordRotator(v.texcoord, _rotateSpeed);
						#endif

						UNITY_TRANSFER_FOG(o,o.vertex);
						return o;
					}

					fixed4 frag(vertexOutput i) : SV_Target
					{
						float2 uv = i.texcoord;

						#if _USEDISTORT_ON					
							float2 newDistortUV = uv.xy * float2(1,1) + float2(0,0);
							float2 mainTexTexel = (float2(_MainTex_TexelSize.z , _MainTex_TexelSize.w));
							float2 distortFromMain = (uv.xy / (100.0 / mainTexTexel));

							float2 lerpDistort;
							#if _DISTORTTEXTURECHANNEL_R
								lerpDistort = lerp(_UVDistortFrom , _UVDistortTo , tex2D(_NoiseTexture, ((distortFromMain + (_UVDistortSpeed * _Time.y)) * _UVDistortNoiseScale)).r);
							#elif _DISTORTTEXTURECHANNEL_G
								lerpDistort = lerp(_UVDistortFrom , _UVDistortTo , tex2D(_NoiseTexture, ((distortFromMain + (_UVDistortSpeed * _Time.y)) * _UVDistortNoiseScale)).g);
							#elif _DISTORTTEXTURECHANNEL_B
								lerpDistort = lerp(_UVDistortFrom , _UVDistortTo , tex2D(_NoiseTexture, ((distortFromMain + (_UVDistortSpeed * _Time.y)) * _UVDistortNoiseScale)).b);
							#endif

							float2 uv_UVDistortShaderMask = uv.xy * _UVDistortShaderMask_ST.xy + _UVDistortShaderMask_ST.zw;

							fixed4 distortMaskTex;

							#if _MASKDISTORTTEXTURECHANNEL_R
								distortMaskTex = tex2D(_UVDistortShaderMask,uv_UVDistortShaderMask).r;
							#elif _MASKDISTORTTEXTURECHANNEL_G
								distortMaskTex = tex2D(_UVDistortShaderMask,uv_UVDistortShaderMask).g;
							#elif _MASKDISTORTTEXTURECHANNEL_B
								distortMaskTex = tex2D(_UVDistortShaderMask,uv_UVDistortShaderMask).b;
							#elif _MASKDISTORTTEXTURECHANNEL_NORMAL
								distortMaskTex = tex2D(_UVDistortShaderMask,uv_UVDistortShaderMask);
							#endif

							float2 FinalUVNoise = (newDistortUV + (lerpDistort * (100.0 / mainTexTexel) * (_UVDistortFade * (distortMaskTex * distortMaskTex.a))));
							uv = FinalUVNoise;
						#endif

						fixed4 texColor = tex2D(_MainTex, uv.xy * _MainTex_ST.xy + _MainTex_ST.zw);
						fixed4 vertexColor = i.vertexColor;

						UNITY_SETUP_INSTANCE_ID(i);
						UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

						#ifdef SOFTPARTICLES_ON
							float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
							float partZ = i.projPos.z;
							float fade = saturate(_InvFade * (sceneZ - partZ));
							i.vertexColor.a *= fade;
						#endif

						#if _TEXTURECHANNEL_R
							fixed texColChannel;
							texColChannel = texColor.r;
						#elif _TEXTURECHANNEL_G
							fixed texColChannel;
							texColChannel = texColor.g;
						#elif _TEXTURECHANNEL_B
							fixed texColChannel;
							texColChannel = texColor.b;
						#elif _TEXTURECHANNEL_NORMAL
							fixed4 texColChannel;
							texColChannel = texColor;
						#endif

							fixed4 FinalColor;

							#if _NOISEFEATURE_VORONOID
								float2 uvNoiseShaderMask = uv.xy * _UVNoiseShaderMask_ST.xy + _UVNoiseShaderMask_ST.zw;

								#if _MASKNOISETEXTURECHANNEL_R
									fixed NoiseShaderMaskColor = tex2D(_UVNoiseShaderMask, uvNoiseShaderMask).r;
								#elif _MASKNOISETEXTURECHANNEL_G
									fixed NoiseShaderMaskColor = tex2D(_UVNoiseShaderMask, uvNoiseShaderMask).g;
								#elif _MASKNOISETEXTURECHANNEL_B
									fixed NoiseShaderMaskColor = tex2D(_UVNoiseShaderMask, uvNoiseShaderMask).b;
								#elif _MASKNOISETEXTURECHANNEL_NORMAL
									fixed4 NoiseShaderMaskColor = tex2D(_UVNoiseShaderMask, uvNoiseShaderMask);
								#endif

								float2 uv100 = 0;
								float3 unityVoronoy = UnityVoronoi(uv.xy, (_noiseSpeed * _Time.y), _noiseScale, uv100);

								#if _TEXTURECHANNEL_NORMAL
									fixed4 noiseColor;
									noiseColor = (texColChannel * pow(unityVoronoy.x, _PowerScale) * (NoiseShaderMaskColor));
								#else
									float noiseColor;
									noiseColor = (texColChannel * pow(unityVoronoy.x, _PowerScale) * (NoiseShaderMaskColor));
								#endif

								FinalColor = vertexColor * _TintColor * noiseColor;

							#elif _NOISEFEATURE_TEXTURE
								float2 uvNoiseShaderMask = uv.xy * _UVNoiseShaderMask_ST.xy + _UVNoiseShaderMask_ST.zw;

								#if _MASKNOISETEXTURECHANNEL_R
									fixed NoiseShaderMaskColor = tex2D(_UVNoiseShaderMask, uvNoiseShaderMask).r;
								#elif _MASKNOISETEXTURECHANNEL_G
									fixed NoiseShaderMaskColor = tex2D(_UVNoiseShaderMask, uvNoiseShaderMask).g;
								#elif _MASKNOISETEXTURECHANNEL_B
									fixed NoiseShaderMaskColor = tex2D(_UVNoiseShaderMask, uvNoiseShaderMask).b;
								#elif _MASKNOISETEXTURECHANNEL_NORMAL
									fixed4 NoiseShaderMaskColor = tex2D(_UVNoiseShaderMask, uvNoiseShaderMask);
								#endif

								float2 customNoiseTexUVSpeed = float2(_PannerNoiseSpeedX,_PannerNoiseSpeedY);
								float2 customNoiseTexUV = uv.xy * _CustomNoiseTexture_ST.xy + _CustomNoiseTexture_ST.zw;
								float2 customNoiseTexPanner = (_Time.y * customNoiseTexUVSpeed + customNoiseTexUV);

								#if _NOISETEXTURECHANNEL_R
									fixed noiseColor = tex2D(_CustomNoiseTexture, customNoiseTexPanner).r;
								#elif _NOISETEXTURECHANNEL_G
									fixed noiseColor = tex2D(_CustomNoiseTexture, customNoiseTexPanner).g;
								#elif _NOISETEXTURECHANNEL_B
									fixed noiseColor = tex2D(_CustomNoiseTexture, customNoiseTexPanner).b;
								#elif _NOISETEXTURECHANNEL_NORMAL
									fixed4 noiseColor = tex2D(_CustomNoiseTexture, customNoiseTexPanner);
								#endif

								#if _TEXTURECHANNEL_NORMAL
									fixed4 finalNoiseColor;
									finalNoiseColor = texColChannel * noiseColor * (NoiseShaderMaskColor);
								#else
									fixed finalNoiseColor;
									finalNoiseColor = texColChannel * noiseColor * (NoiseShaderMaskColor);
								#endif


								FinalColor = vertexColor * _TintColor * finalNoiseColor;
							#elif _NOISEFEATURE_OFF
								FinalColor = vertexColor * _TintColor * texColChannel;
							#endif

						UNITY_APPLY_FOG(i.fogCoord, FinalColor);
						return FinalColor;
					}
					ENDCG
				}
			}
		}
			CustomEditor "NanuqStudioParticleShaderGUI"

}
