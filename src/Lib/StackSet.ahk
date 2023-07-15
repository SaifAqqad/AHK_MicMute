;Ordered collection of unique values
class StackSet{
    __New(elements*){
        this.data:= Array()
        this.occurrences:= {}
        for i, val in elements
            this.push(val)
    }

    push(p_value){
        if (this.occurrences.HasKey(p_value)){
            (this.occurrences[p_value])++
            return 0
        }
        this.data.Push(p_value)
        this.occurrences[p_value]:=1
        return 1
    }

    pushAll(elements*){
        for i, val in elements
            this.push(val)
    }
    
    pop(){
        val:= this.data.Pop()
        this.occurrences.Delete(val)
        return val
    }

    dequeue(){
        val:= this.data.RemoveAt(1)
        this.occurrences.Delete(val)
        return val
    }

    exists(p_value){
        return this.occurrences[p_value]
    }

}