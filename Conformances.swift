import Foundation
import ReactiveSwift
import Workflow

extension Signal: AnyWorkflowConvertible where Error == Never {
    public func asAnyWorkflow() -> AnyWorkflow<Void, Value> {
        return SignalWorkflow(signal: self).asAnyWorkflow()
    }
}

extension SignalProducer: AnyWorkflowConvertible where Error == Never {
    public func asAnyWorkflow() -> AnyWorkflow<Void, Value> {
        return SignalProducerWorkflow(signalProducer: self).asAnyWorkflow()
    }
}

extension Property: AnyWorkflowConvertible {
    public func asAnyWorkflow() -> AnyWorkflow<Value, Never> {
        return PropertyWorkflow(property: self).asAnyWorkflow()
    }
}

private struct SignalWorkflow<Value>: Workflow {
    var signal: Signal<Value, Never>
    
    typealias Output = Value
    
    typealias State = Void
    func makeInitialState() -> State {}
    
    typealias Storage = Lifetime.Token?
    func makeInitialStorage() -> Lifetime.Token? {
        nil
    }
    
    func workflowDidChange(from previousWorkflow: SignalWorkflow, state: inout State) {}
    
    typealias Rendering = Void
    
    func render(state: State, context: RenderContext<SignalWorkflow>) -> Rendering {
        let sink = context.makeSink(of: AnyWorkflowAction.self)
        
        let (lifetime, token) = Lifetime.make()
        context.storage = token
        signal
            .take(during: lifetime)
            .map { AnyWorkflowAction(sendingOutput: $0) }
            .observe(on: QueueScheduler.main)
            .observeValues(sink.send)
    }
}

private struct SignalProducerWorkflow<Value>: Workflow {
    var signalProducer: SignalProducer<Value, Never>
    
    typealias Output = Value
    
    typealias State = Void
    func makeInitialState() -> State {}
    
    typealias Storage = Lifetime.Token?
    func makeInitialStorage() -> Lifetime.Token? {
        nil
    }
    
    func workflowDidChange(from previousWorkflow: SignalProducerWorkflow, state: inout State) {}
    
    typealias Rendering = Void
    
    func render(state: State, context: RenderContext<SignalProducerWorkflow>) -> Rendering {
        let sink = context.makeSink(of: AnyWorkflowAction.self)
        
        let (lifetime, token) = Lifetime.make()
        context.storage = token
        signalProducer
            .take(during: lifetime)
            .map { AnyWorkflowAction(sendingOutput: $0) }
            .observe(on: QueueScheduler.main)
            .startWithValues(sink.send)
    }
}

private struct PropertyWorkflow<Value>: Workflow {
    var property: Property<Value>
    typealias Output = Never
    
    typealias State = Value
    func makeInitialState() -> State {
        return property.value
    }
    
    func workflowDidChange(from previousWorkflow: PropertyWorkflow, state: inout State) {}
    
    typealias Storage = Lifetime.Token?
    func makeInitialStorage() -> Lifetime.Token? { nil }
    
    typealias Rendering = Value
    func render(state: State, context: RenderContext<PropertyWorkflow>) -> Rendering {
        let sink = context.makeSink(of: AnyWorkflowAction.self)
        
        let (lifetime, token) = Lifetime.make()
        context.storage = token
        property
            .signal
            .take(during: lifetime)
            .map { value in
                AnyWorkflowAction { state in
                    state = value
                    return nil
                }
            }
            .observe(on: QueueScheduler.main)
            .observeValues(sink.send)
        return property.value
    }
}

extension RenderContext {
    public func subscribe<Action>(signal: Signal<Action, Never>) where Action: WorkflowAction, WorkflowType == Action.WorkflowType {
        signal.running(with: self)
    }
}
